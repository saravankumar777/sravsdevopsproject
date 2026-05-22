pipeline {

    agent { label 'ec2-agent' }

    environment {
        // SonarCloud
        SONAR_PROJECT    = "sravsdevopsproject"
        SONAR_ORG        = "saravankumar777"

        // Docker & ECR
        DOCKERHUB_CREDS  = credentials('dockerhub-creds')
        AWS_REGION       = "ap-south-1"
        ECR_REGISTRY     = "201048995887.dkr.ecr.us-east-1.amazonaws.com"
        ECR_REPO         = "sravsdevopsproject"
        IMAGE_TAG        = "v${BUILD_NUMBER}"
        IMAGE_NAME       = "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

        // GitHub
        GITHUB_REPO      = "https://github.com/saravankumar777/sravsdevopsproject.git"

        // Kubernetes
        KUBE_NAMESPACE   = "dev"
    }

    stages {

        // ── Stage 1: Git Clone ───────────────────────────────────
        stage('Git Clone') {
            steps {
                git branch: 'main',
                    url: "${GITHUB_REPO}"
                echo "✅ Code cloned from GitHub"
            }
        }

        // ── Stage 2: SonarQube Analysis ─────────────────────────
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarCloud') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            sonar-scanner \
                              -Dsonar.projectKey=${SONAR_PROJECT} \
                              -Dsonar.organization=${SONAR_ORG} \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=https://sonarcloud.io \
                              -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
            post {
                always {
                    timeout(time: 10, unit: 'MINUTES') {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            waitForQualityGate abortPipeline: false
                        }
                    }
                    echo "✅ SonarQube analysis completed"
                }
            }
        }

        // ── Stage 3: OWASP Dependency Check ─────────────────────
        stage('OWASP Dependency Check') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh """
                        /opt/dependency-check/dependency-check/bin/dependency-check.sh \
                          --scan ./ \
                          --format XML \
                          --format HTML \
                          --out . \
                          --project sravsdevopsproject
                    """
                }
            }
            post {
                always {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        dependencyCheckPublisher(
                            pattern: 'dependency-check-report.xml'
                        )
                    }
                    echo "✅ OWASP scan completed"
                }
            }
        }

        // ── Stage 4: Docker Build ────────────────────────────────
        stage('Docker Build') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        # Login to ECR
                        aws ecr get-login-password \
                          --region ${AWS_REGION} | docker login \
                          --username AWS \
                          --password-stdin ${ECR_REGISTRY}

                        # Build Docker image
                        docker build -t ${IMAGE_NAME} .
                        echo "✅ Docker image built: ${IMAGE_NAME}"
                    """
                }
            }
        }

        // ── Stage 5: Trivy Image Scan ────────────────────────────
        stage('Trivy Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh """
                        echo "🔍 Scanning image for vulnerabilities..."
                        trivy image \
                          --exit-code 1 \
                          --severity HIGH,CRITICAL \
                          --no-progress \
                          --ignore-unfixed \
                          --format table \
                          -o trivy-report.txt \
                          ${IMAGE_NAME}
                    """
                }
            }
            post {
                always {
                    sh "cat trivy-report.txt || true"
                    echo "✅ Trivy scan completed"
                }
            }
        }

        // ── Stage 6: Push to ECR ─────────────────────────────────
        stage('Push to ECR') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        # Login to ECR
                        aws ecr get-login-password \
                          --region ${AWS_REGION} | docker login \
                          --username AWS \
                          --password-stdin ${ECR_REGISTRY}

                        # Push image to ECR
                        docker push ${IMAGE_NAME}

                        # Remove local image to free space
                        docker rmi ${IMAGE_NAME}

                        echo "✅ Image pushed to ECR: ${IMAGE_NAME}"
                    """
                }
            }
        }

        // ── Stage 7: Terraform Validation ───────────────────────
        stage('Terraform Validation') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        cd 1.terraform-ec2

                        # Initialize terraform
                        terraform init -backend=false

                        # Validate terraform files
                        terraform validate

                        # Format check
                        terraform fmt -check

                        echo "✅ Terraform validation passed"
                    """
                }
            }
            post {
                failure {
                    echo "❌ Terraform validation failed"
                }
            }
        }

        // ── Stage 8: Kubernetes Deploy ───────────────────────────
        stage('Kubernetes Deploy') {
            steps {
                sh """
                    # Update image in deployment yaml
                    sed -i 's|image:.*|image: ${IMAGE_NAME}|' \
                      3.python-redis-dev.yaml

                    # Apply to Kubernetes cluster
                    kubectl apply -f 3.python-redis-dev.yaml \
                      --namespace ${KUBE_NAMESPACE}

                    # Wait for rollout
                    kubectl rollout status deployment/pythonapp \
                      --namespace ${KUBE_NAMESPACE} \
                      --timeout=120s

                    echo "✅ Deployed to Kubernetes namespace: ${KUBE_NAMESPACE}"
                """
            }
            post {
                success {
                    echo "✅ Kubernetes deployment successful"
                }
                failure {
                    echo "❌ Kubernetes deployment failed"
                    sh """
                        kubectl rollout undo deployment/pythonapp \
                          --namespace ${KUBE_NAMESPACE} || true
                    """
                }
            }
        }

    }

    post {
        success {
            echo "✅ Pipeline SUCCESS — ${IMAGE_NAME} deployed to Kubernetes"
        }
        failure {
            echo "❌ Pipeline FAILED — check logs above"
        }
        always {
            // Clean workspace
            cleanWs()
        }
    }
}