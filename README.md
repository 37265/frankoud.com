<h1 style="text-align: center;">Dev/Learning Log</h1>

<h2 style="text-align: center;">Day 3</h2> 

<h5 style="text-align: right;">19-12-2025</h5>

### Concepts
- Application servers for each domain (using Compose)
- Basic UFW configuration

### Status

I have UFW running (only for traffic directly to the RPi) with `allow` rules for HTTP(S) and SSH and default `deny` rules for other incoming traffic. That should be secure enough for now. I have also remembered/learned how to create Compose files for simple web applications, so that I can start actually hosting something on my domains.

#### Next Steps
Next time, I will:
- Link the existing SSL certificates for `frankoud.com` and `krab.zone` in the separate `.conf` files that I created for them in the repo from which I run the reverse proxy server.
    - These are found in `/etc/letsencrypt/live` and should be mounted to the same path on the container (for convenience).
- Get the apps for `frankoud.com` and `krab.zone` running behind the reverse proxy server (and `frankoud.dev`, because that should be easy after having done two already).
- Look into [this](https://hub.docker.com/r/linuxserver/fail2ban) for Fail2ban with Docker.

[This](https://www.digitalocean.com/community/tutorials/understanding-the-nginx-configuration-file-structure-and-configuration-contexts) may be useful to read as well, to better understand the Nginx config. (← Repeated from yesterday.)

### Challenges

#### Using Docker Compose to automate startup and shutdown
This was relatively simple. I just needed to consult the Docker docs for the Compose syntax and translate the options from yesterday's `run` commands to properties in the `docker-compose.yml` files for each container. 

#### Setting up UFW 

Used [this guide](https://github.com/chaifeng/ufw-docker?tab=readme-ov-file#solving-ufw-and-docker-issues) to supposedly make UFW play nice with Docker. However, just allowing `80`, `443`, and `22` in UFW seems to be okay for now, because I'm not running any containers that expose any other ports than `80` anyway.


### Insights
- If Nginx is running in Docker (very common), I should never refer to containers by container name in your Nginx config. Instead, I should refer to them by the value of the name of the service in the `docker-compose.yml` file, which Docker exposes and resolves via its internal DNS. Basically, the service's name becomes what Nginx sees as the hostname.
- When connecting the Nginx container to the existing bridge networks created for proxied servers, I should declare `existing: true` in the `networks` section of the reverse proxy server's Compose file. Otherwise, it just tries to create new ones. 
- It's a good idea to pass a `.conf` file for every application to the Nginx container, but make sure it has the `.conf` file type, so that Nginx scans it correctly.

### Useful Commands
—

### Mental Model Updates
—

<hr>

<h2 style="text-align: center;">Day 2</h2>

<h5 style="text-align: right;">18-12-2025</h5>

### Concepts
- Running Nginx in Docker
- Docker network
- Routing requests to different proxied servers

### Status

I have Nginx running as a reverse proxy server in a Docker container, connected to one `bridge`-type Docker network for each proxied server. I can reach each proxied server from the RPi with `curl -H "Host: server_name" 127.0.0.1` (which 'tricks' Nginx into routing the request to the correct server). 

From here, I should be able to move this stuff over to Docker Compose, and then throw however many applications I want behind Nginx.

### Challenges

#### Starting Nginx in a Docker container
Using [this guide](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-22-04), I learned how to run an Nginx container with volumes (`-v host/path:container/path`) for both HTML files and a customised Nginx config. The latter became very useful when I wanted to set up several `bridge` networks to isolate proxied servers from each other, and to connect them all (in a many:one fashion) to the Nginx reverse proxy server. This whole process was pretty smooth.

#### Creating Docker networks between Nginx and separate proxied servers
It was a bit of a hassle to set up the custom Nginx config, because the steps for this were slightly different than yesterday's setup for an Nginx reverse proxy server that just runs locally. 

- At first, I wasn't realizing that the host names of the containers would not be recognized anywhere outside of the Nginx container (once they were set up as many:one from proxied servers to Nginx). That was because I had forgotten to start the Nginx server with `-p 80:80`, so the container had no externally exposed ports. 
- I also had to put the server block for each proxied server in Nginx's `default.conf` and copy that onto the container with a volume (`-v`). In the non-containerized implementation, I had created separate files for each 'main' domain to declare server blocks, but that doesn't seem necessary or useful in this case **for now**.
    - This should eventually be split off again for neatness! 

I'm pretty sure `proxy_set_header   Host $host` needed to be set as well, to make sure Nginx properly picks up the `Host` header for any incoming requests.

### Insights
- Nginx can update the contents of a web application (such as HTML changes) when running in Docker, but configuration updates need a restart.
- I can create multiple `bridge`-type networks within Docker to connect Nginx with every proxied server. The proxied servers should not be connected to the default `bridge`(-named) network, so I need to explicitly declare a network connection to prevent proxied servers from connecting to the default network.
- The `server_name` value can just be anything, as long as Nginx actually receives a request with the `Host` header set to that value.
- I need to put `http://[container name]` as the `proxy_pass` value. Obviously, because it's HTTP traffic. 

### Useful Commands
- `docker exec -it [container-name] sh`: Starts a shell in the given container. Can be useful for exploring the container's file system, although it is limited when using a minimal image. 
- Run command for proxy server `docker run --name=docker-nginx --network=test-1 --network=test-2 -p 80:80 -v ~/docker-nginx/html:/usr/share/nginx/html -v ~/docker-nginx/default.conf:/etc/nginx/conf.d/default.conf -d nginx`
- Run command for proxied (test) server: `docker run -d --name=test2 --network=test-2 -v /tmp/test2:/usr/share/nginx/html:ro nginx`

### Mental Model Updates
- Docker container names act as DNS hostnames *only within the same Docker network*
- Host DNS (/etc/hosts) and Docker DNS are entirely separate systems

### Next Steps
Next time, I will work on getting some actual applications running so that my domains show real content. This means I'll need to: 
- Run actual application servers behind Nginx (for frankoud.com, frankoud.dev, and krab.zone)
- Configure SSL with Certbot (separately on the RPi) for each main domain
    - The certificates created by Certbot should live on the RPi and just be mounted on the container with references in the Nginx config.
- Configure security features so that I can actually expose everything to the internet

[This](https://www.digitalocean.com/community/tutorials/understanding-the-nginx-configuration-file-structure-and-configuration-contexts) may be useful to read as well, to better understand the Nginx config.

I'll also see if I can create a neat `docker-compose.yml` to save myself the hassle of typing out every command manually whenever I need to restart a container. 

<hr>

<h2 style="text-align: center;">Day 1</h2>

<h5 style="text-align: right;">17-12-2025</h5>

### Concepts
- GitHub Actions (very minimal, but still)
- Exposing RPi to the world
- Nginx as a reverse proxy
- Dev log

### Challenges

####  Binding Domain(s) to My IP Address
Initially I ran into the problem that I was quite rusty after almost a year of not really doing anything IT-related. 
I knew I had to do something in my Namecheap account to bind the [frankoud.com](http://frankoud.com) domain to my IP address. 
- I added the correct **A Record** and **CNAME Record**, but was still unable to reach my RPi from outside of my LAN.
- Through troubleshooting I found out that I did **not** have a public IP address, so I called my ISP and got one.
- After changing the **A Record** to the new, public IP, I was able to connect to my RPi from everywhere.

#### Setting Up Nginx as a Reverse Proxy

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

### Insights

### Useful Commands
- `sudo nginx -t`: Check the Nginx config for syntax errors.
- `gunicorn --workers=2 test:app`: If you have a minimal `test.py` Python server, this is an easy way to test if Nginx is routing properly.

### Next Steps
Next time, I will work on [setting up a Docker network containing Nginx](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-22-04) and at least two separate, containerized applications, so that I can learn how to properly proxy requests to different servers.