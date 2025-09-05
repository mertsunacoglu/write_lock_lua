-- write_lock.lua

function parse_roles_from_config()
  local roles_table = {}
  local roles_str = rgw.get_config("rgw_keystone_accepted_admin_roles") or ""
  rgw.log(10, "Write-Restriction: Reading roles from config string: '" .. roles_str .. "'")
  for role in string.gmatch(roles_str, "([^,%s]+)") do
    table.insert(roles_table, role)
  end
  return roles_table
end

function has_allowed_role(user_roles, allowed_roles_list)
  if not user_roles then
    return false
  end
  for _, user_role in ipairs(user_roles) do
    for _, allowed_role in ipairs(allowed_roles_list) do
      if user_role == allowed_role then
        return true
      end
    end
  end
  return false
end

local allowed_roles = parse_roles_from_config()
local req = rgw.request
local write_methods = { PUT = true, POST = true, DELETE = true, COPY = true }

if write_methods[req:method()] then
  
  local user_info = req:get_user_info()
  local user_roles = user_info["roles"]
  local is_privileged_user = has_allowed_role(user_roles, allowed_roles)

  rgw.log(10, "Write-Restriction: Method=" .. req:method() .. " User=" .. user_info.user_id .. " Privileged=" .. tostring(is_privileged_user))

  if not is_privileged_user then
    local header_key_s3 = "x-amz-meta-write-restricted"
    local header_key_swift = "x-container-meta-write-restricted"

    if req:get_header(header_key_s3) or req:get_header(header_key_swift) then
      rgw.log(4, "Write-Restriction: Non-privileged user " .. user_info.user_id .. " attempted to set restriction header on bucket " .. req:get_bucket_name())
      return rgw.http_error("403", "Forbidden", "User is not allowed to modify the write-restricted header.")
    end
    
    local bucket_info = req:get_bucket_info()
    if bucket_info and bucket_info.metadata then
      local write_restricted = bucket_info.metadata["x-amz-meta-write-restricted"]
      if write_restricted == "true" then
        rgw.log(4, "Write-Restriction: Blocked write by user " .. user_info.user_id .. " to restricted bucket " .. bucket_info.bucket.name)
        return rgw.http_error("403", "Forbidden", "Writes are restricted for this container.")
      end
    end
  end
end

return nil
