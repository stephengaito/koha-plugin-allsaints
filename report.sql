SELECT
 categories.description AS class,
 CONCAT('<a target="_blank" href="/cgi-bin/koha/members/moremember.pl?borrowernumber=',borrowernumber,'">',firstname, " ", surname,'</a>') AS borrower,
 GROUP_CONCAT('<a target="_blank" href="/cgi-bin/koha/catalogue/detail.pl?biblionumber=',biblionumber,'">',biblio.title,'</a>' SEPARATOR "</br>") AS titles,
 DATE_FORMAT(issuedate, '%Y %b %e') AS 'Date Issued',
 DATEDIFF(CURDATE(), issuedate) DIV 7 AS 'Weeks Out',
 IF( MIN(date_due) <= CURDATE(),CONCAT('<span class="overdue">',DATE_FORMAT(date_due, '%Y %b %e'),'</span>'),DATE_FORMAT(date_due, '%Y %b %e')) AS 'Date Due'
FROM borrowers
JOIN issues USING (borrowernumber)
JOIN items USING (itemnumber)
JOIN biblio USING (biblionumber)
JOIN categories USING (categorycode)
GROUP BY categorycode,date_due,firstname,surname
