#!/bin/bash

# Enable extended globbing for pattern matching
shopt -s extglob

# Set PATH to include a relative folder
PATH=$PATH:./"DV"

# Customize prompt for the select menu
export PS3="RaniaNadaDB>"

# Check if the .db directory exists relative to the script's location
if [[ -d ./.db ]]; then 
    echo "Already DB Created"
else 
    echo "Creating Folder DB ..."
    mkdir ./.db
    sleep 3
fi

# Interactive menu for database operations
select var in "Create DB" "List DB" "Connect DB" "Remove DB" "Exit"
do 
    case $REPLY in
        1 ) # Create DB 
            read -r -p "Enter Database Name: " dbname 
            dbname=$(echo $dbname | tr ' ' '_')
            if [[ $dbname = [0-9]* ]]; then 
                echo "Error 0x0001: DB Name can't start with a number."
            else 
                case $dbname in 
                    +([a-z_A-Z0-9]))
                        if [[ -d ./.db/$dbname ]]; then 
                            echo "Error 0x003: DB already exists."
                        else 
                            mkdir ./.db/$dbname
                        fi 
                    ;;
                    *)
                        echo "Error 0x002: Invalid DB name. No special characters allowed."
                    ;;
                esac
            fi
        ;;
        2) # List DB
            ls -F ./.db | grep / | tr '/' ' '  # Lists all folders
        ;;
        3) # Connect DB
            read -r -p "Enter Database Name: " dbname 
            dbname=$(echo $dbname | tr ' ' '_')
            if [[ $dbname = [0-9]* ]]; then 
                echo "Error 0x0001: DB Name can't start with a number."
            else 
                case $dbname in 
                    +([a-z_A-Z0-9]))
                        if [[ -d ./.db/$dbname ]]; then 
                            echo "Found"
                            cd ./.db/$dbname 
                            export PS3="RaniaNadaTB>"
                            select varr in "create table " "insert" "remove" "select" "Update "
                            
                            do 
                                case $REPLY in
                                1 ) # Create TB 
                                    read -r -p "Enter Table Name: " tbname 
                                    tbname=$(echo $tbname | tr ' ' '_')
                                    if [[ $tbname = [0-9]* ]]; then 
                                        echo "Error 0x0001: TB Name can't start with a number."
                                    else 
                                       case $tbname in 
                                            [a-zA-Z0-9_]*)
                                                if [[ -f ./$tbname.sh ]]; then 
                                                    echo "Error 0x003: Table '$tbname' already exists."
                                                else 
                                                    touch ./$tbname.sh
                                                    read -r -p "Enter the number of columns: " num_columns
                                                    
                                                    # Initialize variables
                                                    table_structure=""
                                                    declare -a columns

                                                    for (( i=1; i<=num_columns; i++ ))
                                                    do
                                                        if [[ $i -eq 1 ]]; then
                                                            echo "Primary Key (PK) Column:"
                                                        else
                                                            echo "Column $i:"
                                                        fi

                                                        # Get column name and check if it already exists
                                                        while true; do
                                                            read -r -p "Enter column name: " colname
                                                            colname=$(echo $colname | tr ' ' '_')

                                                            
                                                            if [[ $colname = [0-9]* ]]; then 
                                                                echo "Error 0x0001: column Name can't start with a number."
                                                            elif [[ $colname =~ ^[^a-zA-Z0-9_].* ]]; then
                                                                echo "Error 0x0002: Column name can't start with a special character or number."
                                                                # Check if column name is already in use
                                                            elif [[ " ${columns[@]} " =~ " $colname " ]]; then
                                                                echo "Error: Column '$colname' already exists. Please choose a different name."
                                                            else
                                                                columns+=("$colname")  # Add the new column name to the array
                                                                break
                                                            fi
                                                        done

                                                        # Get data type
                                                        select datatype in "string" "int"; do
                                                            case $datatype in
                                                                "string")
                                                                    col_type="string"
                                                                    break
                                                                    ;;
                                                                "int")
                                                                    col_type="int"
                                                                    break
                                                                    ;;
                                                                *)
                                                                    echo "Invalid choice. Please select a valid data type."
                                                                    ;;
                                                            esac
                                                        done

                                                        # Mark the first column as PK
                                                        if [[ $i -eq 1 ]]; then
                                                            table_structure+="$colname:$col_type(PK), "
                                                        else
                                                            table_structure+="$colname:$col_type, "
                                                        fi
                                                    done

                                                    # Remove trailing comma and space, then save table structure to file
                                                    table_structure=${table_structure%, }
                                                    echo "$table_structure" > ./$tbname.sh
                                                    echo "Table '$tbname.sh' created with structure: $table_structure"
                                                fi 
                                            ;;
                                            *)
                                                echo "Error 0x002: Invalid Table name. No special characters allowed."
                                            ;;
                                        esac

                                    fi
                                
                                 ;;
                                2) # insertData
                                    is_integer() {
                                            [[ $1 =~ ^-?[0-9]+$ ]]
                                        }

                                        # Prompt for table name
                                        read -r -p "Enter Table Name: " tbname
                                        tbname=$(echo $tbname | tr ' ' '_')

                                        # Check if the table file exists
                                        if [[ ! -f ./$tbname.sh ]]; then
                                            echo "Error: Table '$tbname' does not exist."
                                            exit 1
                                        fi

                                        # Read the table structure (first line) from the file
                                        table_structure=$(head -n 1 ./$tbname.sh)

                                        # Debugging: Print the table structure to verify
                                        echo "Table structure: $table_structure"

                                        # Extract column names and types from the table structure
                                        IFS=', ' read -r -a columns <<< "$table_structure"

                                        # Declare arrays to store column names, types, and primary key values
                                        column_names=()
                                        column_types=()
                                        pk_column=""

                                        # Parse the columns and types
                                        for column in "${columns[@]}"; do
                                            col_name=$(echo "$column" | cut -d ':' -f1)
                                            col_type=$(echo "$column" | cut -d ':' -f2 | tr -d '()')

                                            column_names+=("$col_name")
                                            column_types+=("$col_type")

                                            # Identify the primary key column
                                            if [[ "$column" == *"(PK)"* ]]; then
                                                pk_column="$col_name"
                                            fi
                                        done

                                        # Debugging: Check if primary key column is identified
                                        echo "Primary Key Column: $pk_column"

                                        # Read the number of columns in the table
                                        num_columns=${#column_names[@]}

                                        # Prepare an empty associative array for the new row
                                        declare -A new_row

                                        # Insert values for each column, checking each value sequentially
                                        for ((i=0; i<$num_columns; i++)); do
                                            col_name=${column_names[$i]}
                                            col_type=${column_types[$i]}

                                            # Ask the user to input the value for each column
                                            while true; do
                                                # Check if user entered something or pressed Enter without a value
                                                read -r -p "Enter value for column $col_name ($col_type): " value

                                                if [[ -z "$value" ]]; then
                                                    echo "Error: Please enter a value for column '$col_name'."
                                                else
                                                    # Check if the value matches the data type
                                                    if [[ "$col_type" == "string" ]]; then
                                                        if [[ "$value" =~ ^[a-zA-Z]+$ ]]; then  # Ensure only alphabets for string
                                                            new_row["$col_name"]="$value"
                                                            echo "Value '$value' entered in (string)"
                                                            break  # Exit the inner loop and move to the next column
                                                        else
                                                            echo "Error: Value must be an string for column '$col_name'."
                                                        fi
                                        
                                                    elif [[ "$col_type" == "stringPK" ]]; then
                                                        if [[ "$value" =~ ^[a-zA-Z]+$ ]]; then  # Ensure only alphabets for string
                                                            new_row["$col_name"]="$value"
                                                            echo "Value '$value' entered in (string)"
                                                            break  # Exit the inner loop and move to the next column
                                                        else
                                                            echo "Error: Value must be an string for column '$col_name'."
                                                        fi
                                                        # Exit the inner loop and move to the next column
                                                    elif [[ "$col_type" == "intPK" ]]; then
                                                        if is_integer "$value"; then
                                                            new_row["$col_name"]="$value"
                                                            echo "value $value entered in(str)"
                                                            break  # Exit the inner loop and move to the next column
                                                        else
                                                            echo "Error: Value must be an integer for column '$col_name'."
                                                        fi
                                                    elif [[ "$col_type" == "int" ]]; then
                                                        if is_integer "$value"; then
                                                            new_row["$col_name"]="$value"
                                                            echo "value $value entered in(str)"
                                                            break  # Exit the inner loop and move to the next column
                                                        else
                                                            echo "Error: Value must be an integer for column '$col_name'."
                                                        fi
                                                    else
                                                        echo "Error Raniaaa"
                                                        
                                                    fi
                                                fi
                                            done  # End of the while loop for current column

                                            # If the column is a PK, check for duplicates (only once)
                                            if [[ -n "$pk_column" && "$col_name" == "$pk_column" ]]; then
                                                pk_value=${new_row["$pk_column"]}

                                                # Check if the PK value already exists in the table (simple duplicate check)
                                                if grep -q "$pk_value" ./$tbname.sh; then
                                                    echo "Error: Primary key value '$pk_value' already exists. Cannot insert."
                                                    exit 1  # Exit after error to prevent further insertion
                                                fi
                                            fi
                                        done  # End of the for loop for all columns

                                        # Now that all columns are filled, we can create the row
                                        row=""
                                        for col_name in "${column_names[@]}"; do
                                            row+="${new_row[$col_name]}, "
                                        done
                                        row=${row%, }  # Remove the trailing comma

                                        # Append the new row to the table file
                                        echo "$row" >> ./$tbname.sh
                                        echo "Data inserted successfully into table '$tbname'."

                                ;;
                                3) # DeleteData
                                    # Function to check if a column exists in the table
                                        column_exists() {
                                        local col="$1"
                                        for c in "${column_names[@]}"; do
                                            if [[ "$c" == "$col" ]]; then
                                            return 0
                                            fi
                                        done
                                        return 1
                                        }

                                        # Read Table Name
                                        read -r -p "Enter Table Name: " tbname
                                        tbname=$(echo "$tbname" | tr ' ' '_')

                                        # Check if the table file exists
                                        if [[ ! -f "./$tbname.sh" ]]; then
                                        echo "Error: Table '$tbname' does not exist."
                                        exit 1
                                        fi

                                        # Read the table structure and data from the file
                                        table_structure=$(head -n 1 "./$tbname.sh") # First line is the structure
                                        table_data=$(tail -n +2 "./$tbname.sh")    # Remaining lines are the data

                                        # Extract column names from the table structure
                                        IFS=', ' read -r -a columns <<< "$table_structure"

                                        # Declare an array to store column names
                                        column_names=()
                                        for column in "${columns[@]}"; do
                                        column_names+=("$(echo "$column" | cut -d':' -f1)") # Extract column names
                                        done

                                        # Menu for delete operations
                                        echo "Choose an operation:"
                                        echo "1) DELETE ALL rows from the table"
                                        echo "2) DELETE specific rows WHERE condition"

                                        read -r -p "Enter your choice (1/2): " choice

                                        case $choice in
                                        1) # DELETE ALL rows
                                            read -r -p "Are you sure you want to delete all data? (yes/no): " confirm
                                            if [[ "$confirm" == "yes" ]]; then
                                            # Clear all data but keep the structure
                                            echo "$table_structure" > "./$tbname.sh"
                                            echo "All data has been deleted from table '$tbname'."
                                            else
                                            echo "Operation cancelled."
                                            fi
                                            ;;

                                        2) # DELETE specific rows
                                            echo "Available columns: ${column_names[*]}"
                                            read -r -p "Enter column name for the WHERE condition: " where_column

                                            # Check if column exists
                                            if ! column_exists "$where_column"; then
                                            echo "Error: Column '$where_column' does not exist in the table."
                                            exit 1
                                            fi

                                            read -r -p "Enter value to match for deletion: " where_value

                                            # Find the column index
                                            col_index=-1
                                            for ((i = 0; i < ${#column_names[@]}; i++)); do
                                            if [[ "${column_names[$i]}" == "$where_column" ]]; then
                                                col_index=$i
                                                break
                                            fi
                                            done

                                            if [[ $col_index -eq -1 ]]; then
                                            echo "Error: Could not find column index for '$where_column'."
                                            exit 1
                                            fi

                                            # Create a temporary file to hold filtered data
                                            temp_file=$(mktemp)
                                            echo "$table_structure" > "$temp_file" # Preserve the structure

                                            # Filter out rows that match the condition
                                            while IFS=',' read -r line; do
                                            IFS=',' read -r -a row <<< "$line"
                                            if [[ "${row[$col_index]}" != "$where_value" ]]; then
                                                echo "${row[*]}" >> "$temp_file"
                                            fi
                                            done <<< "$table_data"

                                            # Replace the original table file with the filtered data
                                            mv "$temp_file" "./$tbname.sh"
                                            echo "Rows where '$where_column'='$where_value' have been deleted."
                                            ;;

                                        *)
                                            echo "Invalid choice."
                                            ;;
                                        esac

                                ;;

                                 4) # SelectData
                                        #!/bin/bash

                                        # Function to check if a column exists in the table
                                        column_exists() {
                                            local col="$1"
                                            for c in "${column_names[@]}"; do
                                                if [[ "$c" == "$col" ]]; then
                                                    return 0
                                                fi
                                            done
                                            return 1
                                        }

                                        # Read Table Name
                                        read -r -p "Enter Table Name: " tbname
                                        tbname=$(echo $tbname | tr ' ' '_')

                                        # Check if the table file exists
                                        if [[ ! -f ./$tbname.sh ]]; then
                                            echo "Error: Table '$tbname' does not exist."
                                            exit 1
                                        fi

                                        # Read the table structure and data from the file
                                        table_structure=$(head -n 1 ./$tbname.sh) # First line is the structure
                                        table_data=$(tail -n +2 ./$tbname.sh)    # Remaining lines are the data

                                        # Extract column names from the table structure
                                        IFS=', ' read -r -a columns <<< "$table_structure"

                                        # Declare an array to store column names
                                        column_names=()
                                        for column in "${columns[@]}"; do
                                            col_name=$(echo "$column" | cut -d ':' -f1)
                                            column_names+=("$col_name")
                                        done

                                        # Display Selection Options
                                        echo "Select an option:"
                                        echo "1 - SELECT * FROM $tbname (all rows and columns)"
                                        echo "2 - SELECT specific columns FROM $tbname"
                                        echo "3 - SELECT rows based on a WHERE condition"
                                        read -r -p "Enter your choice (1, 2, or 3): " choice

                                        case $choice in
                                            1)
                                                # Select all columns and rows
                                                echo "Displaying all data from table '$tbname':"
                                                echo "$table_structure"
                                                echo "$table_data"
                                                ;;
                                            2)
                                                # Select specific columns
                                                # Read the table structure (first line) from the file
                                                table_structure=$(head -n 1 ./$tbname.sh)

                                                # Debugging: Print the table structure to verify
                                                echo "Available columns: ${column_names[*]}"
                                                read -r -p "Enter column names separated by commas (e.g., col1,col2): " col_list
                                                IFS=',' read -r -a selected_columns <<< "$col_list"

                                                # Check if all specified columns exist
                                                for col in "${selected_columns[@]}"; do
                                                    column_exists "$col"
                                                    if [[ $? -ne 0 ]]; then
                                                        echo "Error: Column '$col' does not exist."
                                                        exit 1
                                                    fi
                                                done

                                                # Display selected columns and their data
                                                echo "Displaying data for columns: ${selected_columns[*]}"
                                                echo "${selected_columns[*]}"
                                                echo "$table_data" | while IFS=',' read -r -a row; do
                                                    for col in "${selected_columns[@]}"; do
                                                        # Get the index of the column
                                                        for i in "${!column_names[@]}"; do
                                                            if [[ "${column_names[$i]}" == "$col" ]]; then
                                                                echo -n "${row[$i]}, "
                                                            fi
                                                        done
                                                    done
                                                    echo
                                                done
                                                ;;
                                            3)
                                                # Select rows based on a WHERE condition
                                                read -r -p "Enter column name for the WHERE condition: " where_col
                                                column_exists "$where_col"
                                                if [[ $? -ne 0 ]]; then
                                                    echo "Error: Column '$where_col' does not exist."
                                                    exit 1
                                                fi

                                                read -r -p "Enter value for the WHERE condition: " where_value

                                                # Get the index of the column for filtering
                                                where_col_index=-1
                                                for i in "${!column_names[@]}"; do
                                                    if [[ "${column_names[$i]}" == "$where_col" ]]; then
                                                        where_col_index=$i
                                                        break
                                                    fi
                                                done

                                                if [[ $where_col_index -ge 0 ]]; then
                                                    echo "Displaying rows where '$where_col' = '$where_value':"
                                                    echo "$table_structure"
                                                    echo "$table_data" | while IFS=',' read -r -a row; do
                                                        if [[ "${row[$where_col_index]}" == "$where_value" ]]; then
                                                            echo "${row[*]}"
                                                        fi
                                                    done
                                                else
                                                    echo "Error: Unable to find column index for '$where_col'."
                                                fi
                                                ;;
                                            *)
                                                echo "Invalid choice. Exiting."
                                                exit 1
                                                ;;
                                        esac

                                ;;
                                 5) # UpdateData
 
                                                                    #!/bin/bash

                                    # Function to check if a column exists in the table
                                    column_exists() {
                                    local col="$1"
                                    for c in "${column_names[@]}"; do
                                        if [[ "$c" == "$col" ]]; then
                                        return 0
                                        fi
                                    done
                                    return 1
                                    }

                                    # Read Table Name
                                    read -r -p "Enter Table Name: " tbname
                                    tbname=$(echo "$tbname" | tr ' ' '_')

                                    # Check if the table file exists
                                    if [[ ! -f "./$tbname.sh" ]]; then
                                    echo "Error: Table '$tbname' does not exist."
                                    exit 1
                                    fi

                                    # Read the table structure and data from the file
                                    table_structure=$(head -n 1 "./$tbname.sh") # First line is the structure
                                    table_data=$(tail -n +2 "./$tbname.sh")    # Remaining lines are the data

                                    # Extract column names from the table structure
                                    IFS=', ' read -r -a columns <<< "$table_structure"

                                    # Declare an array to store column names
                                    column_names=()
                                    for column in "${columns[@]}"; do
                                    column_names+=("$(echo "$column" | cut -d':' -f1)") # Extract column names
                                    done

                                    # Menu for update operations
                                    echo "Choose an operation:"
                                    echo "1) UPDATE all rows for a specific column"
                                    echo "2) UPDATE specific rows WHERE condition"

                                    read -r -p "Enter your choice (1/2): " choice

                                    case $choice in
                                    1) # UPDATE all rows
                                        echo "Available columns: ${column_names[*]}"
                                        read -r -p "Enter column name to update: " update_column

                                        # Check if column exists
                                        if ! column_exists "$update_column"; then
                                        echo "Error: Column '$update_column' does not exist in the table."
                                        exit 1
                                        fi

                                        read -r -p "Enter new value for column '$update_column': " new_value

                                        # Find the column index
                                        col_index=0
                                        for ((i = 0; i < ${#column_names[@]}; i++)); do
                                        if [[ "${column_names[$i]}" == "$update_column" ]]; then
                                            col_index=$i
                                            break
                                        fi
                                        done

                                        # Create a temporary file to hold updated data
                                        temp_file=$(mktemp)
                                        echo "$table_structure" > "$temp_file" # Preserve the structure

                                        # Update all rows
                                        while IFS=',' read -r -a row; do
                                        # Fix misaligned rows by padding or truncating
                                        while [[ "${#row[@]}" -lt "${#column_names[@]}" ]]; do
                                            row+=("")
                                        done
                                        while [[ "${#row[@]}" -gt "${#column_names[@]}" ]]; do
                                            row=("${row[@]::${#column_names[@]}}")
                                        done

                                        row[$col_index]="$new_value"  # Update the value in the specified column
                                        echo "${row[*]}" | tr ' ' ',' >> "$temp_file"  # Write updated row
                                        done <<< "$table_data"

                                        # Replace the original table file with the updated data
                                        mv "$temp_file" "./$tbname.sh"
                                        echo "All rows updated successfully for column '$update_column'."
                                        ;;

                                    2) # UPDATE specific rows
                                        echo "Available columns: ${column_names[*]}"
                                        read -r -p "Enter column name to update: " update_column

                                        # Check if column exists
                                        if ! column_exists "$update_column"; then
                                        echo "Error: Column '$update_column' does not exist in the table."
                                        exit 1
                                        fi

                                        read -r -p "Enter new value for column '$update_column': " new_value

                                        echo "Available columns for WHERE condition: ${column_names[*]}"
                                        read -r -p "Enter column name for the WHERE condition: " where_column

                                        # Check if column exists for WHERE condition
                                        if ! column_exists "$where_column"; then
                                        echo "Error: Column '$where_column' does not exist in the table."
                                        exit 1
                                        fi

                                        read -r -p "Enter value to match for the WHERE condition: " where_value

                                        # Find the indices of the update column and WHERE column
                                        update_col_index=0
                                        where_col_index=0
                                        for ((i = 0; i < ${#column_names[@]}; i++)); do
                                        if [[ "${column_names[$i]}" == "$update_column" ]]; then
                                            update_col_index=$i
                                        fi
                                        if [[ "${column_names[$i]}" == "$where_column" ]]; then
                                            where_col_index=$i
                                        fi
                                        done

                                        # Create a temporary file to hold updated data
                                        temp_file=$(mktemp)
                                        echo "$table_structure" > "$temp_file" # Preserve the structure

                                        # Update rows that match the WHERE condition
                                        while IFS=',' read -r -a row; do
                                        # Fix misaligned rows by padding or truncating
                                        while [[ "${#row[@]}" -lt "${#column_names[@]}" ]]; do
                                            row+=("")
                                        done
                                        while [[ "${#row[@]}" -gt "${#column_names[@]}" ]]; do
                                            row=("${row[@]::${#column_names[@]}}")
                                        done

                                        if [[ "${row[$where_col_index]}" == "$where_value" ]]; then
                                            row[$update_col_index]="$new_value"  # Update the value
                                        fi
                                        echo "${row[*]}" | tr ' ' ',' >> "$temp_file"  # Write the row
                                        done <<< "$table_data"

                                        # Replace the original table file with the updated data
                                        mv "$temp_file" "./$tbname.sh"
                                        echo "Rows updated successfully where '$where_column'='$where_value'."
                                        ;;

                                    *)
                                        echo "Invalid choice."
                                        ;;
                                    esac

                                ;;
 



                                esac



                            done




                        else 
                            echo "Error 0x003: 404 DB not found."
                        fi 
                    ;;
                    *)
                        echo "Error 0x002: Invalid DB name. No special characters allowed."
                    ;;
                esac
            fi
        ;;
        4) # Remove DB
            read -r -p "Enter Database Name: " dbname 
            dbname=$(echo $dbname | tr ' ' '_')
            if [[ $dbname = [0-9]* ]]; then 
                echo "Error 0x0001: DB Name can't start with a number."
            else 
                case $dbname in 
                    +([a-z_A-Z0-9]))
                        if [[ -d ./.db/$dbname ]]; then 
                            echo "Found"
                            rm -r ./.db/$dbname
                        else 
                            echo "Error 0x003: 404 DB not found."
                        fi 
                    ;;
                    *)
                        echo "Error 0x002: Invalid DB name. No special characters allowed."
                    ;;
                esac
            fi
        ;;
        5) # Exit
            break
        ;;
    esac 
done 
