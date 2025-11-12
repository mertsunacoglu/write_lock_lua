
RGWDebugLog("################################ RGW WRITE-LOCK SCRIPT ################################")

local ADMIN_USER_ID = "adminid"

local write_methods = { 
  PUT = true, 
  POST = true, 
  DELETE = true, 
  COPY = true 
}

local user_id = "anonymous" -- Default to anonymous
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
    return 0 -- Allow
  end

  RGWDebugLog("Write-Restriction: Non-privileged user. Checking restrictions...")

  local header_key = "x-amz-meta-write-restricted"
  local header_value = nil
  if Request.HTTP.Metadata and Request.HTTP.Metadata[header_key] then
     header_value = Request.HTTP.Metadata[header_key]
  end

  if header_value ~= nil then
    RGWDebugLog("Write-Restriction: Non-privileged user " .. user_id .. " attempted to set restriction header. ABORTING.")
    return RGW_ABORT_REQUEST -- Block
  end

  local bucket_metadata = nil
  if Request.Bucket and Request.Bucket.Metadata then
    bucket_metadata = Request.Bucket.Metadata
  end

  if bucket_metadata then
    local write_restricted = bucket_metadata["write-restricted"]
    
    if write_restricted == "true" then
      RGWDebugLog("Write-Restriction: Non-privileged user " .. user_id .. " attempted to write to a restricted bucket. ABORTING.")
      return RGW_ABORT_REQUEST -- Block
    end
  end

  RGWDebugLog("Write-Restriction: Non-privileged user performing normal write to unrestricted bucket. ALLOWING.")
  return 0 -- Allow

end

-- If not a write method (e.g., GET, HEAD, LIST), allow it.
RGWDebugLog("Write-Restriction: Not a write method. Allowing.")
return 0
