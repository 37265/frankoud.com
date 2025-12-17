This document serves as a sort of developer's log / learning diary. Challenges, lessons, and insights are recorded every day.

# Day 1

## Concepts
- GitHub Actions (very minimal, but still)
- Exposing RPi to the world
- Nginx as a reverse proxy
- Dev log

## Challenges

### 1. Binding Domain(s) to My IP Address
Initially I ran into the problem that I was quite rusty after almost a year of not really doing anything IT-related. 
I knew I had to do something in my Namecheap account to bind the [frankoud.com](frankoud.com) domain to my IP address. 
- I added the correct **A Record** and **CNAME Record**, but was still unable to reach my RPi from outside of my LAN.
- Through troubleshooting I found out that I did **not** have a public IP address, so I called my ISP and got one.
- After changing the **A Record** to the new, public IP, I was able to connect to my RPi from everywhere.

### 2. Setting Up Nginx as a Reverse Proxy

1. 
    I had no idea where to start with this, so I followed a [guide](https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-as-a-reverse-proxy-on-ubuntu-22-04) that helped me set up Nginx as a **very basic** reverse proxy server. The content shown below was placed in a `/etc/nginx/sites-available/[domain name]` file. 

    ```
    server {
        listen 80;
        listen [::]:80;

        server_name your_domain www.your_domain;
            
        location / {
            proxy_pass app_server_address; # This is something like http://127.0.0.1:[port]
            include proxy_params;
        }
    }
    ```
    > One instance of this should be used for each 'main' domain that I want to expose. In my case, right now, that's `krab.zone` and `frankoud.com`, but eventually this will probably relate more to separate application containers in Docker.

    After creating a symbolic link to this file in `/etc/nginx/sites-available` and restarting the Nginx service, I was able to reach a `gunicorn` test application listening on `http://127.0.0.1:8000` by visiting `krab.zone` from my browser. 
2. 
    Then it was time to add an SSL certificate to enable HTTPS. For this, I used Certbot. 
    ```
    sudo certbot --nginx -d your_domain.com -d www.your_domain.com
    ```
    > Each `-d` option in this command represents a domain that will be certified. However, it is a good idea to also add subdomains to the certificate for each 'main' domain, although they can be added later on with `certbot --expand [all domains]`.

    After running this command, Certbot had automatically added the links to certificates to the appropriate file in `/etc/nginx/sites-available`. Upon restarting the Nginx service, I was then able to reach the Gunicorn application through HTTPS from my browser.

## Useful Commands
- `sudo nginx -t`: Check the Nginx config for syntax errors.
- `gunicorn --workers=2 test:app`: If you have a minimal `test.py` Python server, this is an easy way to test if Nginx is routing properly.

## Next Steps
Next time, I will work on [setting up a Docker network containing Nginx](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-22-04) and at least two separate, containerized applications, so that I can learn how to properly proxy requests to different servers.