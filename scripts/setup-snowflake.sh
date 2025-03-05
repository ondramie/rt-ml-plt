#!/bin/bash
# setup-snowflake.sh

# Process the SQL file with environment variables
envsubst < seeds/snowflake/setup.sql.template > setup_processed.sql

# Copy and execute in the container
docker cp setup_processed.sql arroyo-snowflake:/tmp/
docker exec arroyo-snowflake snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD -f /tmp/setup_processed.sql

echo "Snowflake setup complete!"
