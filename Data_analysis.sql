select count(*) from Instagram.comments; -- 7488
select count(*) from Instagram.follows; -- 7623
select count(*) from Instagram.likes; -- 8782
select count(*) from Instagram.photos; -- 257
select count(*) from Instagram.photo_tags; -- 501
select count(*) from Instagram.tags; -- 21
select count(*) from Instagram.users; -- 100

-- Find the 5 oldest users.
select id, username, 
date_format(str_to_date(created_at, '%d-%m-%Y %H:%i'), '%Y-%m-%d') as created_at 
from Instagram.users
order by created_at limit 5;

--  We need to figure out when to schedule an ad campgain. 
-- What day of the week do most users register on? 
with day_count (id, day_of_the_week)
as
(select id, 
DAYOFWEEK(date_format(str_to_date(created_at, '%d-%m-%Y %H:%i'), '%Y-%m-%d')) as day_of_the_week
from Instagram.users)
select day_of_the_week, count(id) as total_registration from day_count
group by day_of_the_week
order by total_registration desc limit 1;

-- We want to target our inactive users with an email campaign. 
-- Find the users who have never posted a photo.
select users.username from Instagram.users
left join Instagram.photos on users.id = photos.user_id
where photos.image_url is null;

-- We're running a new contest to see who can get the most likes on a single photo. WHO WON?
select u.username, p.id, p.image_url, count(l.photo_id) as Total_Likes from Instagram.users u
join Instagram.photos p on u.id = p.user_id
join Instagram.likes l on p.id = l.photo_id
group by u.username, p.id, p.image_url
order by Total_Likes desc limit 1;

-- Our Investors want to know: How many times does the average user post? 
-- (total number of photos/total number of users)
select ROUND(COUNT(*)/(SELECT COUNT(*) FROM Instagram.users),2) from Instagram.photos;

-- user ranking by postings higher to lower
select u.username, count(p.id) from Instagram.users u
join Instagram.photos p on u.id = p.user_id
group by u.username
order by count(*) desc;

-- Total Posts by users
select count(*) from Instagram.photos;

-- Total numbers of users who have posted at least one time
select count(distinct user_id) from Instagram.photos;

-- A brand wants to know which hashtags to use in a post. 
-- What are the top 5 most commonly used hashtags?
select t.tag_name, count(p.tag_id) as total from Instagram.tags t
join Instagram.photo_tags p on t.id = p.tag_id
group by t.tag_name
order by total desc limit 5;

-- Find users who have liked every single photo on the site
select u.id, u.username, t.total_likes_by_user from Instagram.users u
join
(select user_id, count(*) as total_likes_by_user from Instagram.likes
group by user_id
order by count(*) desc) t on u.id = t.user_id
where total_likes_by_user = (select count(*) from Instagram.photos)
order by u.id;

-- Find users who have never commented on a photo
select u.username, c.comment_text from Instagram.users u
left join Instagram.comments c on u.id = c.user_id
where c.comment_text is null;

-- Find the percentage of our users who have either never commented on a photo or have commented on every photo
with
tab1 as (select count(user_1) as user_no_comment from (select u.username as user_1, c.comment_text from Instagram.users u
left join Instagram.comments c on u.id = c.user_id
where c.comment_text is null) t),
tab2 as (select count(user_2) as user_all from (select u.id, u.username as user_2, t.total_likes_by_user from Instagram.users u
join
(select user_id, count(*) as total_likes_by_user from Instagram.likes
group by user_id
order by count(*) desc) t on u.id = t.user_id
where total_likes_by_user = (select count(*) from Instagram.photos)
order by u.id) t2)
select user_no_comment, user_all*100/(select count(*) from Instagram.users) as percentage, user_all from tab1, tab2

-- Find users who have ever commented on a photo
select u.username, t.comment_text from Instagram.users u
join
(select user_id, photo_id, comment_text, 
row_number()over(partition by user_id order by cast(photo_id as signed) desc) as N
from Instagram.comments) t on u.id = t.user_id
where N = 1;

-- Find the percentage of our users who have either never commented on a photo or have commented on photos before.
with
users_no_com as (select count(username) as num_users_no_com from Instagram.users
where id not in (select user_id from Instagram.comments)),
users_com as (select count(distinct user_id) as num_users_com from Instagram.comments)
select num_users_no_com, num_users_com * 100/(select count(id) from Instagram.users) as percentage, num_users_com from users_no_com, users_com;
