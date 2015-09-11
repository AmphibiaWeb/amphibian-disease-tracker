DBHelper PHP class
===================

https://github.com/tigerhawkvok/DBHelper

## Configuration:

### Short way

```php
$db = new DBHelper(DATABASE,DATABASE_USER,DATABASE_USER_PASSWORD[,$url = "localhost",$table = null]);
# Highly reccommended
$db->setCols(array(col1,col2,...));
```


### Long way

```php
$db = new DBHelper();
$db->setSQLUser(DEFAULT_SQL_USER);
$db->setDB(DEFAULT_SQL_DATABASE);
$db->setSQLPW(DEFAULT_SQL_PASSWORD);
$db->setSQLURL(DEFAULT_SQL_URL); # Defaults to "localhost" if not set
$db->setTable(DEFAULT_DATABASE_TABLE);
# Highly reccommended
$db->setCols(array(col1,col2,...));
```

## Usage

If you want to change the table being used, be sure to use the `setTable` method.
