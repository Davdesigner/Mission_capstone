"""
Test script for AminoRice API
Run this after starting the API server
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_root():
    print("\n[TEST] Testing Root Endpoint...")
    response = requests.get(f"{BASE_URL}/")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_register():
    print("\n[TEST] Testing User Registration...")
    user_data = {
        "full_name": "Test User",
        "email": "test@example.com",
        "password": "testpass123",
        "phone": "+1234567890"
    }
    
    response = requests.post(f"{BASE_URL}/register", json=user_data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 201

def test_login():
    print("\n[TEST] Testing User Login...")
    login_data = {
        "email": "test@example.com",
        "password": "testpass123"
    }
    
    response = requests.post(f"{BASE_URL}/login", json=login_data)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"[SUCCESS] Login successful!")
        print(f"Token: {data['access_token'][:50]}...")
        return data['access_token']
    else:
        print(f"[FAILED] Login failed: {response.json()}")
        return None

def test_profile(token):
    print("\n[TEST] Testing Get Profile...")
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(f"{BASE_URL}/profile", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_update_profile(token):
    print("\n[TEST] Testing Update Profile...")
    headers = {"Authorization": f"Bearer {token}"}
    params = {
        "full_name": "Updated Test User",
        "phone": "+9876543210"
    }
    
    response = requests.put(f"{BASE_URL}/profile", headers=headers, params=params)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_health():
    print("\n[TEST] Testing Health Check...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def main():
    print("=" * 60)
    print("AminoRice API Test Suite")
    print("=" * 60)
    
    try:
        # Test 1: Root endpoint
        if not test_root():
            print("[FAILED] Root endpoint test failed")
            return
        
        # Test 2: Health check
        if not test_health():
            print("[FAILED] Health check failed")
            return
        
        # Test 3: Register user (may fail if user already exists)
        test_register()
        
        # Test 4: Login
        token = test_login()
        if not token:
            print("[FAILED] Login test failed")
            return
        
        # Test 5: Get profile
        if not test_profile(token):
            print("[FAILED] Profile test failed")
            return
        
        # Test 6: Update profile
        if not test_update_profile(token):
            print("[FAILED] Update profile test failed")
            return
        
        # Test 7: Get updated profile
        if not test_profile(token):
            print("[FAILED] Get updated profile test failed")
            return
        
        print("\n" + "=" * 60)
        print("[SUCCESS] All tests completed successfully!")
        print("=" * 60)
        
    except requests.exceptions.ConnectionError:
        print("\n[ERROR] Could not connect to API")
        print("Make sure the API server is running:")
        print("   uvicorn app:app --reload")
    except Exception as e:
        print(f"\n[ERROR] {str(e)}")

if __name__ == "__main__":
    main()
