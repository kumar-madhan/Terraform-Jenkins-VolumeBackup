pipeline {
    agent any
    
    environment {
        AWS_CREDENTIALS_ID = 'aws-creds' // The ID of the AWS credentials configured in Jenkins
        REGION = 'us-east-1' // The AWS region
        INSTANCE_NAME_PATTERN = 'web_server_*' // Pattern to match instances
        VOLUME_TAGS = 'bin,dom,log' // Comma-separated list of volume tags to be backed up
        
        Name = 'AWS-WEBSERVER'
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
                                aws ec2 describe-instances --filters 'Name=tag:Name,Values=${INSTANCE_NAME_PATTERN}' \
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
                                                 "Name=tag:Name,Values=${tag}" \
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
                                            aws ec2 create-snapshot --volume-id ${volumeId} --description 'Automated backup of ${volumeId} on ${new Date().format('yyyy-MM-dd')}' --query SnapshotId --output text --region ${REGION}
                                        """,
                                        returnStdout: true
                                    ).trim()
                                    echo "Created snapshot ID: ${snapshotId} for volume: ${volumeId}"

                                    // Tag the snapshot with the backup name and date
                                    sh """
                                        aws ec2 create-tags \
                                        --resources ${snapshotId} \
                                        --tags Key=Name,Value="${Name}-${tag}" \
                                                Key=Role,Value="${Role}" \
                                                Key=UserId,Value="${UserId}" \
                                                Key=App_ID,Value="${App_ID}" \
                                        --region ${REGION}
                                    """

                                    // Print statement before storing snapshot information
                                    echo "Storing snapshot information: volumeTag=${tag}, snapshotId=${snapshotId}"

                                    // Store snapshot information
                                    snapshotInfo["${volumeId}-${tag}"] = snapshotId
                                }
                            }
                        }
                    
                        // Save snapshot information to a file
                        def snapshotInfoStr = snapshotInfo.collect { k, v -> "${k} -> ${v}" }.join('\n')
                        writeFile file: 'snapshot_info.txt', text: snapshotInfoStr
                        echo "Snapshot Information:\n${snapshotInfoStr}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Backup completed successfully."
        }
        failure {
            echo "Backup failed."
        }
    }
}
