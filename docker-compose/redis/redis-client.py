import redis
 
# connect to Redis
server = redis.Redis(host="127.0.0.1", port=6379)
 
server.ping()
# should return True
 
server.keys()
# should return [] since we haven't added any keys yet
 
server.get('MyKey')
# should return nothing since we haven't added the key yet
 
server.set('MyKey', 'I love Python')
# should return True
 
server.keys()
# should return [b'MyKey']
 
server.get('MyKey')
# should return "b'I love Python'"
 
server.delete('MyKey')
# should return 1 as success code
 
server.get('MyKey')
# should return nothing because we just deleted the key