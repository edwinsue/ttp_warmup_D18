--Out of all the PSQL functions we have learned so far, for some reason, the one I have the hardest time wrapping my head around 
--is the correlated subquery. In theory, it sounds simple enough. The official documentaion is as such: "A correlated subquery is 
--a subquery that contains a reference to a table (in the parent query) that also appears in the outer query." 
--PostgreSQL evaluates the correlated subquery from inside to outside and the inner subquery cannot run independently on its own.
--So what kind of problem can this function solve? An example would be if I wanted to find out the maximum film length for each rating category
--using the dvdrental database.
--The syntax using the correlated subquery would be:

SELECT 
f1.title,
f1.rating,
f1.length
FROM film f1
WHERE f1.length = 
    (
    SELECT 
    MAX(length)
    FROM film f2
    WHERE f1.rating = f2.rating
    )

--But couldn't I have solved it by using a simple GROUP BY clause where I grouped all the films by their ratings first then took the maximum 
--length of that that rating group? 

SELECT 
rating,
MAX(length) AS length
FROM film
GROUP BY rating

--Ah but the problem arises now when I want to find out the title (or any other details) about that longest film because any AGG function 
--in my SELECT statement requires that all other parameters be included in the GROUP BY clause. But when I include the parameter 'title' as 
--a GROUP BY clause, then PSQL will treat each film as its own individual row since no two films share the same title. In which case
--my output gives back the list of all the films since each film is technically the longest film in its own category (ie it's own title)

SELECT 
rating,
title
MAX(length) AS length
FROM film
GROUP BY rating, title 

--One workaround to this is that I use a CTE to find out the max lengths of each category then join that CTE to my original table so that I
--can isolate all films that have the equivalent length to my max lengths for each category. But then I realize that this is a lot more work
--than the orignal correlated subquery! With the CTE route I had to first create the CTE then work on joining the tables. With big datasets
--or multiple tables, this could prove to be time costly and extremely inefficient. 

WITH maxlength AS 
	(SELECT 
	rating,
	MAX(length) AS length
	FROM film
	GROUP BY rating )

SELECT 
f.title,
f.length,
f.rating
FROM film f
INNER JOIN maxlength ml ON ml.rating=f.rating
WHERE f.length = ml.length
ORDER BY f.title

--But what if I brough out the the big guns? The WINDOW function. I can partition the films by their rating first then take the max film length
--of each partitioned rating? Problem solved! 

SELECT 
f.title,
f.length,
f.rating,
MAX (f.length) OVER (PARTITION BY f.rating) AS max
FROM film f 

--Ah but even that does not work because the WINDOW function only allows me to find a set value (ie the max length for each rating partition)
--for the entire partition. I cannot isolate the film titles that have the said max length value, only compare them  to that value. In fact, 
--when I try to use a HAVING clause I am unable to do so as that is not allowed in WINDOW functions. As a matter of fact, by me trying to incorporate
--a HAVING clause I am essentially trying to do what the correlated subquery does in the first place! Alas PostgreSQL you are a beguiling siren
--confounding in your complexity yet elusive in your simplicity. For problems like these, the correlated subquery reigns king.

SELECT 
f1.title,
f1.rating,
f1.length
FROM film f1
WHERE f1.length = 
    (
    SELECT 
    MAX(length)
    FROM film f2
    WHERE f1.rating = f2.rating
    )
