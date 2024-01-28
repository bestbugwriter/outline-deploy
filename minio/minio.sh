#!/usr/bin/env bash

# 使用 docker 容器内的 minio client， 创建 bucket 和 service account
function createMinioBucketAndAK() {
    # 在  docker 容器内部配置 minio client
    echo "docker exec -it minio mc config host add minio http://localhost:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} "
    docker exec -it minio mc config host add minio http://localhost:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}

    # 使用 docker 容器内的 minio client， 创建 bucket
    echo "docker exec -it minio mc mb minio/${OUTLINE_MINIO_BUCKET}"
    docker exec -it minio mc mb minio/${OUTLINE_MINIO_BUCKET}
    docker exec -it minio mc ls minio/${OUTLINE_MINIO_BUCKET}

    # 使用 docker 容器内的 minio client， 创建 service account
    echo "docker exec -it minio mc admin user svcacct add minio admin --access-key ${MINIO_ADMIN_AK} --secret-key ${MINIO_ADMIN_SK}"
    docker exec -it minio mc admin user svcacct add minio admin --access-key ${MINIO_ADMIN_AK} --secret-key ${MINIO_ADMIN_SK}
}
