.PHONY: help build run run-bg stop logs shell gpu clean push pull

# 变量
IMAGE_NAME := art-e-training
IMAGE_TAG := latest
CONTAINER_NAME := art-e-training
FULL_IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

# 默认目标
help:
	@echo "ART-E Docker 训练 - Makefile 命令"
	@echo ""
	@echo "构建和运行:"
	@echo "  make build      - 构建 Docker 镜像"
	@echo "  make run        - 交互式运行训练"
	@echo "  make run-bg     - 后台运行训练"
	@echo "  make stop       - 停止训练容器"
	@echo ""
	@echo "监控和调试:"
	@echo "  make logs       - 查看容器日志"
	@echo "  make shell      - 进入容器 shell"
	@echo "  make gpu        - 查看 GPU 状态"
	@echo "  make stats      - 查看容器资源使用"
	@echo ""
	@echo "管理:"
	@echo "  make clean      - 清理容器和镜像"
	@echo "  make push       - 推送镜像到 Docker Hub"
	@echo "  make pull       - 从 Docker Hub 拉取镜像"
	@echo ""
	@echo "使用 Docker Compose:"
	@echo "  make up         - 启动服务"
	@echo "  make down       - 停止服务"
	@echo "  make restart    - 重启服务"

# 构建镜像
build:
	@echo "🔨 构建 Docker 镜像..."
	cd ../.. && docker build -f examples/art-e/Dockerfile -t $(FULL_IMAGE) .
	@echo "✅ 构建完成"

# 交互式运行
run:
	@echo "🚀 启动训练（交互模式）..."
	@if [ ! -f .env ]; then \
		echo "⚠️  警告: .env 文件不存在"; \
		exit 1; \
	fi
	docker run --rm -it \
		--name $(CONTAINER_NAME) \
		--gpus all \
		--env-file .env \
		-v $(PWD)/data:/workspace/examples/art-e/data \
		-v $(PWD)/outputs:/workspace/examples/art-e/outputs \
		-v $(PWD)/checkpoints:/workspace/examples/art-e/checkpoints \
		--shm-size=16g \
		--ipc=host \
		$(FULL_IMAGE)

# 后台运行
run-bg:
	@echo "🚀 启动训练（后台模式）..."
	@if [ ! -f .env ]; then \
		echo "⚠️  警告: .env 文件不存在"; \
		exit 1; \
	fi
	mkdir -p data outputs checkpoints
	docker run -d \
		--name $(CONTAINER_NAME) \
		--gpus all \
		--env-file .env \
		-v $(PWD)/data:/workspace/examples/art-e/data \
		-v $(PWD)/outputs:/workspace/examples/art-e/outputs \
		-v $(PWD)/checkpoints:/workspace/examples/art-e/checkpoints \
		--shm-size=16g \
		--ipc=host \
		--restart=unless-stopped \
		$(FULL_IMAGE)
	@echo "✅ 容器已启动"
	@echo "查看日志: make logs"

# 停止容器
stop:
	@echo "🛑 停止容器..."
	docker stop $(CONTAINER_NAME) || true
	@echo "✅ 已停止"

# 查看日志
logs:
	docker logs -f $(CONTAINER_NAME)

# 进入容器
shell:
	docker exec -it $(CONTAINER_NAME) bash

# 查看 GPU
gpu:
	nvidia-smi

# 查看资源使用
stats:
	docker stats $(CONTAINER_NAME)

# 清理
clean:
	@echo "🧹 清理容器和镜像..."
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true
	docker rmi $(FULL_IMAGE) 2>/dev/null || true
	@echo "✅ 清理完成"

# 推送到 Docker Hub
push:
	@echo "📤 推送镜像到 Docker Hub..."
	@read -p "Docker Hub 用户名: " username; \
	docker tag $(FULL_IMAGE) $$username/$(FULL_IMAGE); \
	docker push $$username/$(FULL_IMAGE)
	@echo "✅ 推送完成"

# 从 Docker Hub 拉取
pull:
	@echo "📥 拉取镜像..."
	@read -p "Docker Hub 用户名: " username; \
	docker pull $$username/$(FULL_IMAGE); \
	docker tag $$username/$(FULL_IMAGE) $(FULL_IMAGE)
	@echo "✅ 拉取完成"

# Docker Compose 命令
up:
	docker-compose up -d
	@echo "✅ 服务已启动"
	@echo "查看日志: docker-compose logs -f"

down:
	docker-compose down
	@echo "✅ 服务已停止"

restart:
	docker-compose restart
	@echo "✅ 服务已重启"

# 查看镜像
images:
	docker images | grep $(IMAGE_NAME)

# 查看容器
ps:
	docker ps -a | grep $(CONTAINER_NAME)

