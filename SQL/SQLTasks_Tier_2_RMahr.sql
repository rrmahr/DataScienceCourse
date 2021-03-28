/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name 
FROM Facilities
WHERE membercost > 0

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT( name )
FROM Facilities
WHERE membercost >0

-- Result is 5


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost < (monthlymaintenance *.2)

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1,5)


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE WHEN monthlymaintenance > 100 THEN 'expensive'
WHEN monthlymaintenance <= 100 THEN 'cheap' END AS FeeAmt
FROM Facilities


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

-- To check for Tennis Courts

SELECT DISTINCT name, facid
FROM Facilities

-- Tennis Courts are facid 0, 1

SELECT f.name AS Court, CONCAT(m.surname," ",m.firstname) AS Member 
FROM Members AS m
INNER JOIN Bookings AS b
ON m.memid = b.memid
INNER JOIN Facilities AS f
ON b.facid = f.facid
WHERE b.facid IN (0,1)
GROUP BY Member
ORDER BY Member

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name AS Court, CONCAT( m.surname, " ", m.firstname ) AS Member,
CASE WHEN m.memid =0 THEN f.guestcost
WHEN m.memid > 0 THEN f.membercost
END AS Cost
FROM Members AS m
INNER JOIN Bookings AS b ON m.memid = b.memid
INNER JOIN Facilities AS f ON b.facid = f.facid
WHERE starttime LIKE '2012-09-14%'
AND ((m.memid = 0 AND f.guestcost>30) OR (m.memid > 0 AND f.membercost>30))
ORDER BY Cost DESC


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT Court, Member, Cost
FROM 
	(SELECT f.name AS Court, CONCAT( m.surname, " ", m.firstname ) AS Member,
	CASE WHEN m.memid =0 THEN f.guestcost
	WHEN m.memid > 0 THEN f.membercost
	END AS Cost
	FROM Members AS m
	INNER JOIN Bookings AS b ON m.memid = b.memid
	INNER JOIN Facilities AS f ON b.facid = f.facid
	WHERE starttime LIKE '2012-09-14%') AS subquery
WHERE Cost > 30
ORDER BY Cost DESC



/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions. 

 QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

import sqlite3
from sqlite3 import Error

def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(sqlite3.version)
    except Error as e:
        print(e)
 
    return conn

database = "sqlite_db_pythonsqlite.db"
conn = create_connection(database)
cur = conn.cursor()
	
query = """SELECT Facility, Revenue
FROM 
    (SELECT f.name as Facility, 
    CASE WHEN m.memid=0 THEN SUM(b.slots) * f.guestcost
    WHEN m.memid>0 THEN SUM(b.slots) * f.membercost
    END AS Revenue
    FROM Members AS m
    INNER JOIN Bookings AS b ON m.memid = b.memid
    INNER JOIN Facilities AS f ON b.facid = f.facid) AS subquery
WHERE Revenue < 1000
ORDER BY Revenue
"""

cur.execute(query)
rows = cur.fetchall()
for row in rows:
    print(row)

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

query = """SELECT m1.surname, m1.firstname, m2.surname AS rec_surname, m2.firstname AS rec_firstname
FROM Members AS m1
LEFT JOIN Members AS m2
ON m1.recommendedby = m2.memid
ORDER BY m1.surname, m1.firstname
"""

cur.execute(query)
rows = cur.fetchall()
for row in rows:
    print(row)


/* Q12: Find the facilities with their usage by member, but not guests */

query = """SELECT m.surname, m.firstname, f.name AS Facility, SUM(b.slots) AS Usage
FROM Members AS m
INNER JOIN Bookings AS b 
ON m.memid = b.memid
INNER JOIN Facilities AS f 
ON b.facid = f.facid
WHERE m.memid > 0
GROUP BY m.surname, m.firstname
ORDER BY Usage DESC
"""

cur.execute(query)
rows = cur.fetchall()
for row in rows:
    print(row)

/* Q13: Find the facilities usage by month, but not guests */

query = """SELECT 
CASE WHEN starttime LIKE ('%-01-%') THEN 'Jan'
WHEN starttime LIKE ('%-02-%') THEN 'Feb'
WHEN starttime LIKE ('%-03-%') THEN 'Mar'
WHEN starttime LIKE ('%-04-%') THEN 'Apr'
WHEN starttime LIKE ('%-05-%') THEN 'May'
WHEN starttime LIKE ('%-06-%') THEN 'Jun'
WHEN starttime LIKE ('%-07-%') THEN 'Jul'
WHEN starttime LIKE ('%-08-%') THEN 'Aug'
WHEN starttime LIKE ('%-09-%') THEN 'Sep'
WHEN starttime LIKE ('%-10-%') THEN 'Oct'
WHEN starttime LIKE ('%-11-%') THEN 'Nov'
WHEN starttime LIKE ('%-12-%') THEN 'Dec' 
END AS Month, f.name AS Facility, SUM(b.slots) AS Usage
FROM Members AS m
INNER JOIN Bookings AS b 
ON m.memid = b.memid
INNER JOIN Facilities AS f 
ON b.facid = f.facid
WHERE m.memid > 0
GROUP BY Month, Facility
ORDER BY Month, Usage DESC
"""

cur.execute(query)
rows = cur.fetchall()
for row in rows:
    print(row)