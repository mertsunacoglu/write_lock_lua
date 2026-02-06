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

local method = Request.Method or (Request.HTTP and Request.HTTP.Method)

if method and write_methods[method] then
  RGWDebugLog("Write-Restriction: Is a write method (" .. method .. "). Checking permissions...")

  if is_privileged_user then
    RGWDebugLog("Write-Restriction: Privileged user. ALLOWING write.")
    return 0 
  end

  if Request.Bucket and Request.Bucket.Tags then
    
    local lock_status = Request.Bucket.Tags[LOCK_TAG_KEY]
    
    if lock_status == LOCK_TAG_VALUE then
       RGWDebugLog("Write-Restriction: LOCKED. User " .. user_id .. " attempted to write to a restricted bucket.")
       return RGW_ABORT_REQUEST
    end
    
    RGWDebugLog("Write-Restriction: Bucket is not locked (Tag '".. LOCK_TAG_KEY .."' is " .. tostring(lock_status) .. "). ALLOWING.")
  else
    RGWDebugLog("Write-Restriction: No bucket tags found (or not a bucket request). ALLOWING.")
  end

  return 0 
end

return 0