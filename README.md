This document is a developer's log / learning diary. Challenges, lessons, and insights are recorded every day.

# Day 2

###### 18-12-2025

## Concepts
- Running Nginx in Docker
- Docker network
- Routing requests to different proxied servers

## Status: 

I have Nginx running as a reverse proxy server in a Docker container, connected to one `bridge`-type Docker network for each proxied server. I can reach each proxied server from the RPi with `curl -H "Host: server_name" 127.0.0.1` (which 'tricks' Nginx into routing the request to the correct server). 

From here, I should be able to move this stuff over to Docker Compose, and then throw however many applications I want behind Nginx.

## Challenges

### Starting Nginx in a Docker container
Using [this guide](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-22-04), I learned how to run an Nginx container with volumes (`-v host/path:container/path`) for both HTML files and a customised Nginx config. The latter became very useful when I wanted to set up several `bridge` networks to isolate proxied servers from each other, and to connect them all (in a many:one fashion) to the Nginx reverse proxy server. This whole process was pretty smooth.

### Creating Docker networks between Nginx and separate proxied servers
It was a bit of a hassle to set up the custom Nginx config, because the steps for this were slightly different than yesterday's setup for an Nginx reverse proxy server that just runs locally. 

- At first, I wasn't realizing that the host names of the containers would not be recognized anywhere outside of the Nginx container (once they were set up as many:one from proxied servers to Nginx). That was because I had forgotten to start the Nginx server with `-p 80:80`, so the container had no externally exposed ports. 
- I also had to put the server block for each proxied server in Nginx's `default.conf` and copy that onto the container with a volume (`-v`). In the non-containerized implementation, I had created separate files for each 'main' domain to declare server blocks, but that doesn't seem necessary or useful in this case **for now**.
    - This should eventually be split off again for neatness! 

I'm pretty sure `proxy_set_header   Host $host` needed to be set as well, to make sure Nginx properly picks up the `Host` header for any incoming requests.

## Insights
- Nginx can update the contents of a web application (such as HTML changes) when running in Docker, but configuration updates need a restart.
- I can create multiple `bridge`-type networks within Docker to connect Nginx with every proxied server. The proxied servers should not be connected to the default `bridge`(-named) network, so I need to explicitly declare a network connection to prevent proxied servers from connecting to the default network.
- The `server_name` value can just be anything, as long as Nginx actually receives a request with the `Host` header set to that value.
- I need to put `http://[container name]` as the `proxy_pass` value. Obviously, because it's HTTP traffic. 

## Useful Commands
- `docker exec -it [container-name] sh`: Starts a shell in the given container. Can be useful for exploring the container's file system, although it is limited when using a minimal image. 
- Run command for proxy server `docker run --name=docker-nginx --network=test-1 --network=test-2 -p 80:80 -v ~/docker-nginx/html:/usr/share/nginx/html -v ~/docker-nginx/default.conf:/etc/nginx/conf.d/default.conf -d nginx`
- Run command for proxied (test) server: `docker run -d --name=test2 --network=test-2 -v /tmp/test2:/usr/share/nginx/html:ro nginx`

## Mental Model Updates
- Docker container names act as DNS hostnames *only within the same Docker network*
- Host DNS (/etc/hosts) and Docker DNS are entirely separate systems

## Next Steps
Next time, I will work on getting some actual applications running so that my domains show real content. This means I'll need to: 
- Run actual application servers behind Nginx (for frankoud.com, frankoud.dev, and krab.zone)
- Configure SSL with Certbot (separately on the RPi) for each main domain
    - The certificates created by Certbot should live on the RPi and just be mounted on the container with references in the Nginx config.
- Configure security features so that I can actually expose everything to the internet

[This](https://www.digitalocean.com/community/tutorials/understanding-the-nginx-configuration-file-structure-and-configuration-contexts) may be useful to read as well, to better understand the Nginx config.

I'll also see if I can create a neat `docker-compose.yml` to save myself the hassle of typing out every command manually whenever I need to restart a container. 

# Day 1 
###### 17-12-2025

## Concepts
- GitHub Actions (very minimal, but still)
- Exposing RPi to the world
- Nginx as a reverse proxy
- Dev log

## Challenges

###  Binding Domain(s) to My IP Address
Initially I ran into the problem that I was quite rusty after almost a year of not really doing anything IT-related. 
I knew I had to do something in my Namecheap account to bind the [frankoud.com](http://frankoud.com) domain to my IP address. 
- I added the correct **A Record** and **CNAME Record**, but was still unable to reach my RPi from outside of my LAN.
- Through troubleshooting I found out that I did **not** have a public IP address, so I called my ISP and got one.
- After changing the **A Record** to the new, public IP, I was able to connect to my RPi from everywhere.

### Setting Up Nginx as a Reverse Proxy

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

    After creating a symbolic link to this file in `/etc/nginx/sites-enabled/` and restarting the Nginx service, I was able to reach a `gunicorn` test application listening on `http://127.0.0.1:8000` by visiting `krab.zone` from my browser. 
2. 
    Then it was time to add an SSL certificate to enable HTTPS. For this, I used Certbot. 
    ```
    sudo certbot --nginx -d your_domain.com -d www.your_domain.com
    ```
    > Each `-d` option in this command represents a domain that will be certified. However, it is a good idea to also add subdomains to the certificate for each 'main' domain, although they can be added later on with `certbot --expand [all domains]`.

    After running this command, Certbot had automatically updated the server blocks with certificates in the appropriate files in `/etc/nginx/sites-available/`, i.e. the files (from all the files linked in `/etc/nginx/sites-enabled/`) in which it **first** found the server blocks specified in the `-d` options. Upon restarting the Nginx service, I was then able to reach the Gunicorn application through HTTPS from my browser.

## Insights

## Useful Commands
- `sudo nginx -t`: Check the Nginx config for syntax errors.
- `gunicorn --workers=2 test:app`: If you have a minimal `test.py` Python server, this is an easy way to test if Nginx is routing properly.

## Next Steps
Next time, I will work on [setting up a Docker network containing Nginx](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-22-04) and at least two separate, containerized applications, so that I can learn how to properly proxy requests to different servers.