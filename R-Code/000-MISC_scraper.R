## Scraper.R
# This script tries - in vain - 
# to connect to Thinlab and retrieve
# the json export of the porjects.


library(dplyr)
# install.packages("rvest") # Make sure you have it!


# Proper way to do it -----------------------------------------------------

start_url <- 'http://thinklab.com/login'
email <- "myemail"
passwd <- "myPasswd"

# Initialize session
session <- rvest::html_session(start_url)

# login
sign_in_form <- rvest::html_form(session)[[3]]
sign_in_form <- rvest::set_values(sign_in_form, 
                                  email = email,
                                  password = passwd)
sign_in_form$url <- "" # THIS IS A BUG, see https://github.com/hadley/rvest/issues/141

# In spite of the concordance of the csrf token in the form with
# the one in the cookie, I get a csrf token error. 
# (you need real email/password to run in the error)
logged_in <- session %>% rvest::submit_form(sign_in_form)
  
## Retrive the file
export <- logged_in %>% 
  rvest::jump_to("http://thinklab.com/p/rephetio/export.json") %>% 
  `[[`("response") %>% content


# Do it by hand ------------------------------------------------------------------

## We tried here to specify everything ourselves to bypass the 
## rvest package (in case the session state was not handled properly)
## and we get the same error.

header_list <- c(
  'Cookie' = 'orig_referrer=https://www.google.com/; thread_view=191,; _gat=1; csrftoken=arbitrary; pv=anonymous; _ga=GA1.2.1147535651.1460154913',
  'Origin' = 'http://thinklab.com',
  'Accept-Encoding' = 'gzip, deflate',
  'Accept-Language' = 'en-US,en;q=0.8,fr;q=0.6,en-GB;q=0.4',
  'Upgrade-Insecure-Requests' = '1',
  'User-Agent' = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.110 Safari/537.36',
  'Content-Type' = 'application/x-www-form-urlencoded',
  'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  'Cache-Control' = 'max-age=0',
  'Referer' = 'http://thinklab.com/login',
  'Connection' = 'keep-alive')

# This give the same csrf problem as above.
suppressWarnings(httr::handle_reset(start_url))
response <- httr::POST(url = start_url, #"http://httpbin.org/headers", 
                       encode = "form",
                       body = list(email = email, 
                                   password = passwd,
                                   csrfmiddlewaretoken = 'arbitrary',
                                   save = 'Continue'),
                       httr::add_headers(.headers = header_list))


# Get list of pages -------------------------------------------------------
# Quite elegant

rvest:::html_session("http://thinklab.com/projects") %>% 
  rvest::html_nodes("a.list-proj-name") %>% 
  rvest::html_attrs() %>% sapply(., '[[', 'href')

rvest:::html_session("http://thinklab.com/proposals") %>% 
  rvest::html_nodes("a.list-proj-name") %>% 
  rvest::html_attrs() %>% sapply(., '[[', 'href')







