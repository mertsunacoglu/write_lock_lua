
RGWDebugLog("################################ RGW WRITE-LOCK SCRIPT ################################")

local ADMIN_USER_ID = "adminid"

local write_methods = { 
  PUT = true, 
  POST = true, 
  DELETE = true, 
  COPY = true 
}

local user_id = "anonymous"
local is_privileged_user = false

if Request and Request.User and Request.User.Id then
  user_id = Request.User.Id
  RGWDebugLog("Write-Restriction: Found User.Id: " .. user_id)
else
  RGWDebugLog("Write-Restriction: Could not find Request.User.Id. Treating as non-privileged.")
end

if user_id == ADMIN_USER_ID then
  is_privileged_user = true
end
RGWDebugLog("Write-Restriction: User=" .. user_id .. " Privileged=" .. tostring(is_privileged_user))

local method = nil
if Request and Request.HTTP and Request.HTTP.Method then
  method = Request.HTTP.Method
end

if method and write_methods[method] then
  RGWDebugLog("Write-Restriction: Is a write method (" .. method .. "). Checking permissions...")

  if is_privileged_user then
    RGWDebugLog("Write-Restriction: Privileged user. ALLOWING all write operations.")
    return 0 
  end
-- Always allow the Admin
  if is_privileged_user then
    RGWDebugLog("Write-Restriction: Privileged user. ALLOWING write.")
    return 0 
  end

  -- For non-privileged users, check the BUCKET metadata
  if Request.Bucket and Request.Bucket.Metadata then
    local bucket_meta = Request.Bucket.Metadata
    
    local write_restricted = bucket_meta["x-amz-meta-write-restricted""]
    
    if write_restricted == "true" then
      RGWDebugLog("Write-Restriction: LOCKED. User " .. user_id .. " attempted to write to a restricted bucket.")
      Request.Response.Message = "Write blocked by bucket metadata lock"
      return RGW_ABORT_REQUEST
    end
    
    RGWDebugLog("Write-Restriction: Bucket is not locked. ALLOWING.")
  else
    RGWDebugLog("Write-Restriction: No bucket metadata found (or not a bucket request). ALLOWING.")
  end

  return 0 
end

-- Allow non-write methods (GET, HEAD, etc.)
return 0