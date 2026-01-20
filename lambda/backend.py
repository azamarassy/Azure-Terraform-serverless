import json

def lambda_handler(event, context):
    """
    Placeholder for the backend API logic.
    """
    print(f"Received event: {json.dumps(event)}")
    
    response_body = {
        "message": "Hello from Azure Functions (migrated from AWS Lambda)!",
        "input": event
    }
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }

if __name__ == "__main__":
    # Example local test
    test_event = {"httpMethod": "GET", "path": "/data"}
    print(lambda_handler(test_event, None))
