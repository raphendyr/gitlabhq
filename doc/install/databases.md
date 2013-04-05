# Setup Database

GitLab supports the following databases:

* MySQL (preferred)
* PostgreSQL


## MySQL

    # Install the database packages
    sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

    # Login to MySQL
    mysql -u root -p

    # Create a user for GitLab. (change $password to a real password)
    mysql> CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '$password';

    # Create the GitLab production database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

    # Grant the GitLab user necessary permissopns on the table.
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'localhost';

    # Quit the database session
    mysql> \q

    # Try connecting to the new database with the new user
    sudo -u git -H mysql -u gitlab -p -D gitlabhq_production

## PostgreSQL

Install the database packages

    sudo apt-get install -y postgresql-9.1 libpq-dev

Create a user for GitLab (replace git with username you are using for gitlab).

    sudo -u postgres createuser -D -R -S git

* Add option `-c <number>` to limit simultaneous connections for your user
* Add option `-P` for command to ask password (If you for some reason need to user tcp connection)

Create the GitLab production database & grant all privileges on database (make above user the owner)

    sudo -u postgres createdb -O git gitlabhq_production "Gitlab production database."

Try connecting to the new database with the new user

    sudo -u git -H psql -d gitlabhq_production

* If you are using password, then use `psql -h <hostname> -W -U git gitlabhq_production`
