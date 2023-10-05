<p align="center">
<img width="400" alt="self-hosted" src="https://github.com/MirekNguyen/self-hosted/assets/65291610/9b4eb572-f8a1-4a7f-ab15-cb40987ad3cd">
</p>

# Self hosted

I host numerous Docker services on my Raspberry Pi 4, this setup simplifies inter-container communication and enables flexible management. With custom Bash scripts and configurations, I can enable and disable containers on restart and control service states according to my needs.
Please feel free to visit my website at [mirekng.com](https://mirekng.com/) to learn more about me and my projects.

## Getting Started

### Prerequisites

You will need linux server and docker

## Installation

1. Clone the repository: `git clone https://github.com/mireknguyen/mirekng-homepage.git`
2. Navigate to the project directory: cd mirekng-homepage
3. Run the automation script to set up Docker services.
```
./docker-services-up
```

## Usage

- To start the Docker services, run:
```
cd <project-folder> && ./docker-services-up
```
- To stop the services, run:
```
cd <project-folder> && ./docker-services-down
```

## Systemd

1. Create a systemd file
```
touch /etc/systemd/system/self-hosted.service
```

2. Add this (use your installation directory)
```
[Unit]
Description=%i service with docker compose
PartOf=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/home/user/self-hosted/
ExecStart=/home/user/self-hosted/docker-services-up
ExecStop=/home/user/self-hosted/docker-services-down

[Install]
WantedBy=multi-user.target
```
