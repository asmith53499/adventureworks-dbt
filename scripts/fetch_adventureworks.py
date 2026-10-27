"""Download the AdventureWorks OLTP sample data and convert it into dbt seeds.

Microsoft publishes AdventureWorks as a SQL Server install script (instawdb.sql)
plus one data file per table. Those files are not standard CSV:

  * there is no header row - column names only exist in the CREATE TABLE DDL
  * most files are tab-delimited, but tables with XML/free-text columns use
    '+|' between fields and '&|\\n' between rows
  * computed columns (e.g. SalesOrderNumber, TotalDue) are included in the data

This script parses the DDL and BULK INSERT options out of instawdb.sql, splits
each data file accordingly, drops columns that are noise or sensitive for an
analytics project, and writes UTF-8 CSVs with snake_case headers to
seeds/adventureworks/.

Usage:
    python scripts/fetch_adventureworks.py                  # download from GitHub
    python scripts/fetch_adventureworks.py --source-dir DIR # use local copies
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path

SOURCE_URL = (
    "https://raw.githubusercontent.com/microsoft/sql-server-samples/master/"
    "samples/databases/adventure-works/oltp-install-script"
)
REPO_ROOT = Path(__file__).resolve().parents[1]
SEED_DIR = REPO_ROOT / "seeds" / "adventureworks"

# (schema, table) pairs that feed the Sales subject area. Everything else in the
# OLTP database (manufacturing, purchasing, HR history, passwords, photos) is
# intentionally left out.
TABLES = [
    ("Sales", "SalesOrderHeader"),
    ("Sales", "SalesOrderDetail"),
    ("Sales", "SalesOrderHeaderSalesReason"),
    ("Sales", "SalesReason"),
    ("Sales", "SalesTerritory"),
    ("Sales", "SalesPerson"),
    ("Sales", "SalesPersonQuotaHistory"),
    ("Sales", "Customer"),
    ("Sales", "Store"),
    ("Sales", "SpecialOffer"),
    ("Sales", "CurrencyRate"),
    ("Sales", "Currency"),
    ("Purchasing", "ShipMethod"),
    ("Production", "Product"),
    ("Production", "ProductSubcategory"),
    ("Production", "ProductCategory"),
    ("Production", "ProductModel"),
    ("Production", "ProductCostHistory"),
    ("Person", "Person"),
    ("Person", "Address"),
    ("Person", "StateProvince"),
    ("Person", "CountryRegion"),
    ("HumanResources", "Employee"),
]

# rowguid is a replication artifact present on most tables; it carries no meaning.
DROP_EVERYWHERE = {"rowguid"}

# Per-table drops: XML blobs, spatial/hierarchy types, and fields that look like
# PII or payment data. None of them are needed for the sales models.
DROP_COLUMNS = {
    "SalesOrderHeader": {"CreditCardID", "CreditCardApprovalCode"},
    "Store": {"Demographics"},
    "ProductModel": {"CatalogDescription", "Instructions"},
    "Person": {"AdditionalContactInfo", "Demographics"},
    "Address": {"SpatialLocation"},
    "Employee": {
        "NationalIDNumber",
        "LoginID",
        "OrganizationNode",
        "BirthDate",
        "MaritalStatus",
        "Gender",
    },
}

# Source column names that collide with SQL reserved words on DuckDB/Snowflake.
RENAME_COLUMNS = {
    "SalesTerritory": {"Group": "TerritoryGroup"},
}


@dataclass
class TableSpec:
    schema: str
    name: str
    columns: list[str]
    field_terminator: str = "\t"
    row_terminator: str = "\n"


def snake_case(name: str) -> str:
    """SalesOrderID -> sales_order_id, SalesYTD -> sales_ytd."""
    name = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name)
    return name.lower()


def decode_terminator(raw: str) -> str:
    if raw.lower().startswith("0x"):
        return bytes.fromhex(raw[2:]).decode()
    return raw.replace("\\t", "\t").replace("\\n", "\n")


def parse_install_script(sql: str) -> dict[str, TableSpec]:
    specs: dict[str, TableSpec] = {}

    # CREATE TABLE blocks end at the first line that starts with ')'.
    for match in re.finditer(
        r"^CREATE TABLE \[(\w+)\]\.\[(\w+)\]\((.*?)^\)", sql, re.M | re.S
    ):
        schema, table, body = match.groups()
        columns = [
            col.group(1)
            for line in body.splitlines()
            if (col := re.match(r"\s+\[(\w+)\]", line))
        ]
        specs[table] = TableSpec(schema, table, columns)

    # BULK INSERT ... WITH ( ... ); carries the delimiters for each data file.
    for match in re.finditer(
        r"BULK INSERT \[\w+\]\.\[(\w+)\] FROM .*?WITH \((.*?)\);", sql, re.S
    ):
        table, options = match.groups()
        if table not in specs:
            continue
        if field := re.search(r"FIELDTERMINATOR\s*=\s*'([^']*)'", options):
            specs[table].field_terminator = decode_terminator(field.group(1))
        if row := re.search(r"ROWTERMINATOR\s*=\s*'([^']*)'", options):
            specs[table].row_terminator = decode_terminator(row.group(1))

    return specs


def read_source(name: str, source_dir: Path | None) -> str:
    if source_dir:
        return (source_dir / name).read_text(encoding="utf-8-sig")
    print(f"  downloading {name}", file=sys.stderr)
    with urllib.request.urlopen(f"{SOURCE_URL}/{name}") as resp:
        return resp.read().decode("utf-8-sig")


def convert_table(spec: TableSpec, raw: str, out_path: Path) -> int:
    drop = DROP_EVERYWHERE | DROP_COLUMNS.get(spec.name, set())
    keep = [i for i, col in enumerate(spec.columns) if col not in drop]
    renames = RENAME_COLUMNS.get(spec.name, {})
    header = [snake_case(renames.get(spec.columns[i], spec.columns[i])) for i in keep]

    rows = [r for r in raw.split(spec.row_terminator) if r.strip()]
    with out_path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(header)
        for line_no, row in enumerate(rows, start=1):
            fields = row.rstrip("\r").split(spec.field_terminator)
            if len(fields) != len(spec.columns):
                raise ValueError(
                    f"{spec.name} row {line_no}: expected {len(spec.columns)} "
                    f"fields, got {len(fields)}"
                )
            writer.writerow([fields[i] for i in keep])
    return len(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--source-dir",
        type=Path,
        help="directory holding instawdb.sql and the raw data files "
        "(skips downloading)",
    )
    args = parser.parse_args()

    specs = parse_install_script(read_source("instawdb.sql", args.source_dir))
    SEED_DIR.mkdir(parents=True, exist_ok=True)

    for schema, table in TABLES:
        spec = specs[table]
        assert spec.schema == schema, f"{table} found in {spec.schema}"
        out_path = SEED_DIR / f"{snake_case(table)}.csv"
        n = convert_table(spec, read_source(f"{table}.csv", args.source_dir), out_path)
        print(f"{schema + '.' + table:<45} {n:>8,} rows -> {out_path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
