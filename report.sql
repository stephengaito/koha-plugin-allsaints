

SELECT
 categories.description AS class,
 CONCAT('<a target="_blank" href="/cgi-bin/koha/members/moremember.pl?borrowernumber=',borrowernumber,'">',firstname, " ", surname,'</a>') AS borrower,
 GROUP_CONCAT('<a target="_blank" href="/cgi-bin/koha/catalogue/detail.pl?biblionumber=',biblionumber,'">',biblio.title,'</a>' SEPARATOR "</br>") AS titles,
 IF( MIN(date_due) <= CURDATE(),CONCAT('<span class="overdue">',MIN(date_due),'</span>'),MIN(date_due)) AS due
FROM borrowers
JOIN issues USING (borrowernumber)
JOIN items USING (itemnumber)
JOIN biblio USING (biblionumber)
JOIN categories USING (categorycode)
GROUP BY categorycode,firstname,surname

