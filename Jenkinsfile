pipeline {
    agent any
    
    environment {
        AWS_CREDENTIALS_ID = 'aws-creds'
        REGION = 'us-east-1'
        STACK_PATTERN = 'AWS-WEB-SERVER*'
        VOLUME_TAGS = 'EBSVolumeBin,EBSVolumeDom,EBSVolumeLog'
        
        STACK_NAME = 'AWS-WEB-SERVER'
        Role = 'App'
        UserId = 'Kumar-madhan'
        App_ID = 'Web-App-01'
    }
    
    stages {
        stage('Create Snapshots') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    script {
                        def instanceIds = sh(
                            script: """
                                aws ec2 describe-instances --filters 'Name=tag:aws:cloudformation:stack-name,Values=${STACK_PATTERN}' \
                                    --output text --query 'Reservations[*].Instances[*].InstanceId' --region ${REGION}
                            """, 
                            returnStdout: true
                        ).trim().split()

                        def snapshotInfo = [:]
                        def volumeTags = VOLUME_TAGS.split(',')

                        for (instanceId in instanceIds) {
                            echo "Processing instance: ${instanceId}"
                            for (tag in volumeTags) {
                                def volumeIds = sh(
                                    script: """
                                        aws ec2 describe-volumes \
                                        --filters "Name=attachment.instance-id,Values=${instanceId}" \
                                                 "Name=tag:aws:cloudformation:logical-id,Values=${tag}" \
                                        --query "Volumes[*].VolumeId" \
                                        --output text \
                                        --region ${REGION}
                                    """, 
                                    returnStdout: true
                                ).trim().split()
                                
                                for (volumeId in volumeIds) {
                                    echo "Creating snapshot for volume: ${volumeId} with tag: ${tag}"
                                    def snapshotId = sh(
                                        script: """
                                            aws ec2 create-snapshot --volume-id ${volumeId} --description ${STACK_NAME} --query SnapshotId --output text --region ${REGION}
                                        """,
                                        returnStdout: true
                                    ).trim()
                                    echo "Created snapshot ID: ${snapshotId} for volume: ${volumeId}"

                                    // Tag the snapshot with the backup name and date
                                    sh """
                                        aws ec2 create-tags \
                                        --resources ${snapshotId} \
                                        --tags Key=Name,Value="${STACK_NAME}-${tag}" \
                                                Key=Role,Value="${Role}" \
                                                Key=UserId,Value="${UserId}" \
                                                Key=App_ID,Value="${App_ID}" \
                                        --region ${REGION}
                                    """

                                    // Print statement before storing snapshot information
                                    echo "Storing snapshot information: volumeTag=${tag}, snapshotId=${snapshotId}"

                                    // Store snapshot information
                                    snapshotInfo["${tag}"] = snapshotId
                                }
                            }
                        }
                    
                        // Save snapshot information to a JSON file
                        def snapshotInfoJson = new groovy.json.JsonBuilder(snapshotInfo).toPrettyString()
                        writeFile file: 'snapshot_info.json', text: snapshotInfoJson
                        echo "Snapshot Information:\n${snapshotInfoJson}"
                    }
                }
            }
        },
        stage('Deploy CloudFormation') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    script {
                        def snapshotInfo = readJSON file: 'snapshot_info.json'
                        
                        def params = snapshotInfo.collect { k, v -> ["ParameterKey": k, "ParameterValue": v] }

                        // Deploy CloudFormation stack with the specified region
                        sh """
                            aws cloudformation deploy --template-file updated_template.json \
                                                    --stack-name ${STACK_NAME} \
                                                    --parameter-overrides ${params.collect { p -> "${p.ParameterKey}=${p.ParameterValue}" }.join(' ')} \
                                                    --region ${REGION}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Backup and deployment completed successfully."
        }
        failure {
            echo "Backup or deployment failed."
        }
    }
}
