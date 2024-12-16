# A387-Jarkom-Labs

For run this project make sure `npm` are installed.

---

How to run the project:

1. Install node modules

```
npm install
```

2. Run project

```
npm run start
```

## Architecture
![AWS Sample Architecture Dicoding](https://github.com/user-attachments/assets/8dba5c54-fb63-48ab-bbf5-fe84b6a8fd11)



## Think that've added

- Automatically setup the project requirement 
- Automatically installing nginx, certbot, pm2
- Reverse proxy configuration



## Reference

[Terraform on AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)


## Environment Variables

Before deployment to AWS, you will need to add the following environment variables to your .env file or setup directly in terminal

`AWS_ACCESS_KEY_ID = `

`AWS_SECRET_ACCESS_KEY = `

`AWS_REGION = `

If stuck, refer to this link for setup environment variables

[Credential Access Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

[Video Reference](https://youtu.be/2iC7R32C-EQ?si=iWYEG9nktjKuYK3K)

Also, create the "key pair" first before deployment to easily connect to EC2 instance

[Reference to Create EC2 Keypair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)


## Deployment

For deployment after the environment variables setup, follow these step

Initialize terraform first

```bash
  terraform init
```

Take a preview

```bash
  terraform plan
```

Deploy with auto approve

```bash
  terraform apply --auto-approve
```
## Setup Limit Access (Optional, best practices for prevent DDOS)

1. Connect to EC2 Instance using Instance Connect then edit the file "/etc/nginx/sites-available/default" (if the node js still running, stop it first)

```bash
  sudo nano /etc/nginx/sites-available/default
```

2. Add the following value before `server` block
```bash
  limit_req_zone $binary_remote_addr zone=one:10m rate=30r/m;
```
That means root can only make request every 2 second (30 request/minutes)

Then add again the following value in the `location` block
```bash
  limit_req zone=one;
```

3. Save & Restart Nginx

```bash
  sudo systemctl restart nginx
```

4. Run the project again using pm2
```bash
  cd /home/ubuntu/dicoding-a387-jarkom-labs/
  pm2 start app.js --name "simple-express-app-firmansyw30"
```
## Setup subdomain dcdg.xyz (optional)

1. Connect to EC2 Instance using Instance Connect. Change the value of "<public IP EC2 instance>" with actual Public IP

```bash
  curl -X POST -H "Content-type: application/json" -d "{ \"ip\": \"<public IP EC2 instance>\" }" "https://sub.dcdg.xyz/dns/records"
```

Note the `hostname` value.
[Example](https://dicoding-web-img.sgp1.cdn.digitaloceanspaces.com/original/academy/dos:b077990a643a0ccfdb8478a557e4fe5420220322102040.jpeg)


2. Add the "hostname" values to nginx by edit the file "/etc/nginx/sites-available/default"
```bash
  sudo nano /etc/nginx/sites-available/default
```

Paste the values of the "hostname" in the `server_name` section

![Screenshot 2024-12-16 230144 (ss subdomain)](https://github.com/user-attachments/assets/3e3a9018-395b-4ca2-b297-25c5d62cc14b)


3. Save & Restart Nginx

```bash
  sudo systemctl restart nginx
```

4. Run the project again using pm2
```bash
  cd /home/ubuntu/dicoding-a387-jarkom-labs/
  pm2 start app.js --name "simple-express-app-firmansyw30"
```

## Configuring TLS Certificate (optional)

1. Connect to EC2 Instance using Instance Connect. Change the value of "<public IP EC2 instance>" with actual Public IP

```bash
sudo certbot --nginx -d <yourdomain.com> -d <www.yourdomain.com>
```

Replace the <yourdomain.com> and <www.yourdomain.com> with the actual value

[Example](https://dicoding-web-img.sgp1.cdn.digitaloceanspaces.com/original/academy/dos:01def23cce20989fcaa3a696b987c66220220322105832.jpeg)


2. Answer the question


3. After answering the question, run the project again using pm2
```bash
  cd /home/ubuntu/dicoding-a387-jarkom-labs/
  pm2 start app.js --name "simple-express-app-firmansyw30"
```

## Tech Stack

**Server:** Node, Express

**Tool:** Terraform, PM2 (Process Manager NodeJS)

**Services:** Amazon EC2, VPC


## Authors

[@firmansyw30](https://www.github.com/firmansyw30) and still learning


## Support

For support, email firmansyahwicaksono30@gmail.com


## Lessons Learned

Maybe next time I'll be add RDS Instance to configuring the connectivity

