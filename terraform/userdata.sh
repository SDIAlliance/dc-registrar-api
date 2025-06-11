#!/bin/bash

dnf install -y docker
systemctl enable docker
systemctl start docker
