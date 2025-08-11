"""
AWS Guardrail Auto-Remediation Lambda Function
Automatically remediates certain guardrail violations
"""

import json
import logging
import boto3
from botocore.exceptions import ClientError, BotoCoreError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
ec2_client = boto3.client('ec2')
sns_client = boto3.client('sns')
config_client = boto3.client('config')

def lambda_handler(event, context):
    """
    Main Lambda handler for guardrail auto-remediation
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse the Config compliance change event
        detail = event.get('detail', {})
        config_rule_name = detail.get('configRuleName', '')
        compliance_type = detail.get('newEvaluationResult', {}).get('complianceType', '')
        resource_type = detail.get('resourceType', '')
        resource_id = detail.get('resourceId', '')
        
        logger.info(f"Processing compliance change for rule: {config_rule_name}")
        logger.info(f"Resource: {resource_type}/{resource_id}, Compliance: {compliance_type}")
        
        # Only process non-compliant resources
        if compliance_type != 'NON_COMPLIANT':
            logger.info("Resource is compliant, no action needed")
            return {
                'statusCode': 200,
                'body': json.dumps('Resource is compliant')
            }
        
        # Route to appropriate remediation function
        remediation_result = route_remediation(config_rule_name, resource_type, resource_id, detail)
        
        # Send notification if configured
        sns_topic_arn = context.get('SNS_TOPIC_ARN')
        if sns_topic_arn:
            send_notification(sns_topic_arn, config_rule_name, resource_id, remediation_result)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Remediation completed',
                'rule': config_rule_name,
                'resource': resource_id,
                'result': remediation_result
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing remediation: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def route_remediation(config_rule_name, resource_type, resource_id, detail):
    """
    Route remediation based on the Config rule name
    """
    remediation_functions = {
        's3_bucket_public_access_prohibited': remediate_s3_public_access,
        's3_bucket_server_side_encryption_enabled': remediate_s3_encryption,
        'incoming_ssh_disabled': remediate_security_group_ssh,
        'vpc_flow_logs_enabled': remediate_vpc_flow_logs,
        'root_access_key_check': remediate_root_access_keys
    }
    
    remediation_func = remediation_functions.get(config_rule_name.lower())
    
    if remediation_func:
        logger.info(f"Executing remediation function for {config_rule_name}")
        return remediation_func(resource_type, resource_id, detail)
    else:
        logger.warning(f"No remediation function found for rule: {config_rule_name}")
        return {'status': 'no_remediation', 'message': 'No remediation available'}

def remediate_s3_public_access(resource_type, resource_id, detail):
    """
    Remediate S3 bucket public access by enabling public access block
    """
    try:
        bucket_name = resource_id
        
        # Enable public access block
        s3_client.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        
        logger.info(f"Successfully enabled public access block for bucket: {bucket_name}")
        return {
            'status': 'success',
            'action': 'enabled_public_access_block',
            'resource': bucket_name
        }
        
    except ClientError as e:
        logger.error(f"Failed to remediate S3 public access: {str(e)}")
        return {
            'status': 'failed',
            'error': str(e),
            'resource': resource_id
        }

def remediate_s3_encryption(resource_type, resource_id, detail):
    """
    Remediate S3 bucket encryption by enabling default encryption
    """
    try:
        bucket_name = resource_id
        
        # Enable default encryption
        s3_client.put_bucket_encryption(
            Bucket=bucket_name,
            ServerSideEncryptionConfiguration={
                'Rules': [
                    {
                        'ApplyServerSideEncryptionByDefault': {
                            'SSEAlgorithm': 'AES256'
                        }
                    }
                ]
            }
        )
        
        logger.info(f"Successfully enabled encryption for bucket: {bucket_name}")
        return {
            'status': 'success',
            'action': 'enabled_bucket_encryption',
            'resource': bucket_name
        }
        
    except ClientError as e:
        logger.error(f"Failed to remediate S3 encryption: {str(e)}")
        return {
            'status': 'failed',
            'error': str(e),
            'resource': resource_id
        }

def remediate_security_group_ssh(resource_type, resource_id, detail):
    """
    Remediate security group with open SSH access
    """
    try:
        sg_id = resource_id
        
        # Get current security group rules
        response = ec2_client.describe_security_groups(GroupIds=[sg_id])
        security_group = response['SecurityGroups'][0]
        
        # Find and revoke rules with open SSH access (port 22, 0.0.0.0/0)
        for rule in security_group['IpPermissions']:
            if (rule.get('FromPort') == 22 and rule.get('ToPort') == 22 and 
                rule.get('IpProtocol') == 'tcp'):
                
                for ip_range in rule.get('IpRanges', []):
                    if ip_range.get('CidrIp') == '0.0.0.0/0':
                        # Revoke the rule
                        ec2_client.revoke_security_group_ingress(
                            GroupId=sg_id,
                            IpPermissions=[{
                                'IpProtocol': 'tcp',
                                'FromPort': 22,
                                'ToPort': 22,
                                'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                            }]
                        )
                        
                        logger.info(f"Successfully revoked open SSH rule from security group: {sg_id}")
                        return {
                            'status': 'success',
                            'action': 'revoked_open_ssh_rule',
                            'resource': sg_id
                        }
        
        return {
            'status': 'no_action',
            'message': 'No open SSH rules found',
            'resource': sg_id
        }
        
    except ClientError as e:
        logger.error(f"Failed to remediate security group SSH: {str(e)}")
        return {
            'status': 'failed',
            'error': str(e),
            'resource': resource_id
        }

def remediate_vpc_flow_logs(resource_type, resource_id, detail):
    """
    Remediate VPC without flow logs by enabling flow logs
    """
    try:
        vpc_id = resource_id
        
        # Create flow logs for the VPC
        response = ec2_client.create_flow_logs(
            ResourceIds=[vpc_id],
            ResourceType='VPC',
            TrafficType='ALL',
            LogDestinationType='cloud-watch-logs',
            LogGroupName=f'/aws/vpc/flowlogs/{vpc_id}',
            DeliverLogsPermissionArn='arn:aws:iam::{}:role/flowlogsRole'.format(
                boto3.client('sts').get_caller_identity()['Account']
            )
        )
        
        logger.info(f"Successfully enabled flow logs for VPC: {vpc_id}")
        return {
            'status': 'success',
            'action': 'enabled_vpc_flow_logs',
            'resource': vpc_id,
            'flow_log_ids': response.get('FlowLogIds', [])
        }
        
    except ClientError as e:
        logger.error(f"Failed to remediate VPC flow logs: {str(e)}")
        return {
            'status': 'failed',
            'error': str(e),
            'resource': resource_id
        }

def remediate_root_access_keys(resource_type, resource_id, detail):
    """
    Remediate root access keys (this requires manual intervention)
    """
    logger.warning("Root access keys detected - manual intervention required")
    return {
        'status': 'manual_intervention_required',
        'message': 'Root access keys must be manually deleted',
        'resource': resource_id,
        'action_required': 'Delete root user access keys via AWS Console'
    }

def send_notification(sns_topic_arn, config_rule_name, resource_id, remediation_result):
    """
    Send notification about remediation action
    """
    try:
        message = {
            'rule': config_rule_name,
            'resource': resource_id,
            'remediation_result': remediation_result,
            'timestamp': context.aws_request_id if 'context' in globals() else 'unknown'
        }
        
        subject = f"Guardrail Auto-Remediation: {config_rule_name}"
        
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=json.dumps(message, indent=2)
        )
        
        logger.info(f"Sent notification to SNS topic: {sns_topic_arn}")
        
    except ClientError as e:
        logger.error(f"Failed to send SNS notification: {str(e)}")

def get_resource_details(resource_type, resource_id):
    """
    Get additional details about the resource for better remediation
    """
    try:
        if resource_type == 'AWS::S3::Bucket':
            response = s3_client.get_bucket_location(Bucket=resource_id)
            return {'region': response.get('LocationConstraint', 'us-east-1')}
        
        elif resource_type == 'AWS::EC2::SecurityGroup':
            response = ec2_client.describe_security_groups(GroupIds=[resource_id])
            return response['SecurityGroups'][0] if response['SecurityGroups'] else {}
        
        elif resource_type == 'AWS::EC2::VPC':
            response = ec2_client.describe_vpcs(VpcIds=[resource_id])
            return response['Vpcs'][0] if response['Vpcs'] else {}
            
    except ClientError as e:
        logger.error(f"Failed to get resource details: {str(e)}")
        return {}
    
    return {}
