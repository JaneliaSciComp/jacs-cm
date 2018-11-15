CREATE USER flyportalAdmin@'%' IDENTIFIED BY 'FeWO4O';
GRANT SUPER ON *.* TO flyportalAdmin@'%';
GRANT ALL PRIVILEGES on flyportal.* to flyportalAdmin@'%';
CREATE USER flyportalApp@'%' IDENTIFIED BY 'FeWO4W';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, SHOW VIEW on flyportal.* to flyportalApp@'%';
CREATE USER flyportalRead@'%' IDENTIFIED BY 'flyportalRead';
GRANT SELECT on flyportal.* to flyportalRead@'%';
