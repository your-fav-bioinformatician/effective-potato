import pyodbc


def check_connection():
    conn_str = (
        "Driver={ODBC Driver 17 for SQL Server};"
        "Server=.\\SQLEXPRESS;"
        "Database=Users_db;"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )

    try:
        print("Attempting to connect...")
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        print("Connection Successful!")

        # Check current DB
        cursor.execute("SELECT DB_NAME()")
        db_name = cursor.fetchone()[0]
        print(f"Current Database Context: {db_name}")

        # List Tables
        print("Listing tables in this DB:")
        cursor.execute("SELECT name FROM sys.tables")
        tables = [row[0] for row in cursor.fetchall()]
        print(tables)

        if "Users" in tables:
            print("SUCCESS: 'Users' table found.")
            # Check columns
            cursor.execute("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users'")
            cols = [row[0] for row in cursor.fetchall()]
            print(f"Columns: {cols}")
        else:
            print("FAILURE: 'Users' table NOT found in this database.")

        conn.close()

    except Exception as e:
        print(f"CONNECTION FAILED: {e}")


if __name__ == "__main__":
    check_connection()