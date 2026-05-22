pipeline {

    agent { label 'ec2-agent' }

    environment {
        // SonarCloud
        SONAR_PROJECT   = "sravsdevopsproject"
        SONAR_ORG       = "saravankumar777"

        // Docker
        DOCKERHUB_CREDS = credentials('dockerhub-creds')
        IMAGE_NAME      = "vishwacloudlab/pythonapp"
        IMAGE_TAG       = "v${BUILD_NUMBER}"

        // GitHub
        GITHUB_REPO     = "https://github.com/saravankumar777/sravsdevopsproject.git"
    }

    stages {

        // ── Stage 1: Checkout Code ───────────────────────────────
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: "${GITHUB_REPO}"
            }
        }

        // ── Stage 2: SonarQube Code Scan ────────────────────────
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
        }

         ── Stage 3: Quality Gate ────────────────────────────────
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ── Stage 4: OWASP Dependency Check ──────────────────────
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck(
                    additionalArguments: '''
                        --scan .
                        --format HTML
                        --format XML
                        --out dependency-check-report
                        --prettyPrint
                    ''',
                    odcInstallation: 'OWASP-DC'
                )
            }
            post {
                always {
                    // Publish the report in Jenkins UI
                    dependencyCheckPublisher(
                        pattern: 'dependency-check-report/dependency-check-report.xml'
                    )
                }
                success {
                    echo "✅ OWASP scan passed — no critical dependency vulnerabilities"
                }
                failure {
                    echo "❌ OWASP found vulnerable dependencies — check report"
                }
            }
        }

        // ── Stage 5: Build Docker Image ──────────────────────────
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        // ── Stage 6: Trivy Image Scan ────────────────────────────
        stage('Trivy Image Scan') {
            steps {
                sh """
                    echo "Scanning image for vulnerabilities..."

                    # Scan and save report
                    trivy image \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      --no-progress \
                      --format table \
                      -o trivy-report.txt \
                      ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
            post {
                always {
                    // Show report in Jenkins even if scan fails
                    sh "cat trivy-report.txt || true"
                }
                failure {
                    echo "❌ Trivy found HIGH/CRITICAL vulnerabilities — stopping pipeline"
                }
                success {
                    echo "✅ Trivy scan passed — no HIGH/CRITICAL vulnerabilities found"
                }
            }
        }

        // ── Stage 7: Push to DockerHub ───────────────────────────
        // stage('Push to DockerHub') {
        //     steps {
        //         sh """
        //             echo ${DOCKERHUB_CREDS_PSW} | docker login \
        //               -u ${DOCKERHUB_CREDS_USR} --password-stdin
        //             docker push ${IMAGE_NAME}:${IMAGE_TAG}
        //             docker rmi ${IMAGE_NAME}:${IMAGE_TAG}
        //         """
        //     }
        // }

        // ── Stage 8: Update Helm values.yaml ────────────────────
        // stage('Update Helm Values') {
        //     steps {
        //         withCredentials([string(credentialsId: 'github-token', variable: 'GIT_TOKEN')]) {
        //             sh """
        //                 sed -i 's|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' \
        //                   pythonapp-chart/values.yaml

        //                 git config user.email "jenkins@ci.com"
        //                 git config user.name "Jenkins"
        //                 git add pythonapp-chart/values.yaml
        //                 git commit -m "Update image tag to ${IMAGE_TAG}"
        //                 git push https://${GIT_TOKEN}@github.com/saravankumar777/sravsdevopsproject.git main
        //             """
        //         }
        //     }
        // }

    }

    post {
        success {
            echo "✅ Pipeline SUCCESS — ${IMAGE_NAME}:${IMAGE_TAG} deployed"
        }
        failure {
            echo "❌ Pipeline FAILED — check logs above"
        }
    }
}