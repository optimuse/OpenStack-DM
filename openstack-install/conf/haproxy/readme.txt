Don't use httpck, rather use tcp-check.
Ceilometer will always respond with 401 Unauthorized if a token is not sent.
Since httpck only passes if the response is 20x or 30x, it'll never work.
Using tcp-check, it marks it up if the daemon is listening.
