-- normalize.lua
-- Normalizes log records for consistent schema in OpenSearch
-- Handles both single-line and multiline (stack trace) entries

function normalize_record(tag, timestamp, record)
    -- For multiline entries, the 'log' field contains the full entry
    -- The parser filter extracts fields from the first line only
    -- The 'message' field from parser contains just the first line's message
    -- We need to append the continuation lines to the message
    
    local raw_log = record["log"]
    local parsed_message = record["message"]
    
    -- If we have both raw log and parsed message, check if there's more content
    if raw_log and parsed_message then
        -- Find where the first line ends (after the parsed portion)
        -- The continuation lines start after the first newline
        local first_newline = string.find(raw_log, "\n")
        if first_newline then
            -- There are continuation lines - append them to the message
            local continuation = string.sub(raw_log, first_newline)
            record["message"] = parsed_message .. continuation
        end
    end
    
    -- For .err files without parser, extract level from line if possible
    if not record["level"] and raw_log then
        -- Check for Java-style WARNING: at start
        if string.match(raw_log, "^WARNING:") then
            record["level"] = "warning"
        elseif string.match(raw_log, "^ERROR:") then
            record["level"] = "error"
        elseif string.match(raw_log, "^INFO:") then
            record["level"] = "info"
        end
    end
    
    -- Normalize level to lowercase and standardize names
    if record["level"] then
        local level = string.lower(record["level"])
        -- OMERO uses fixed-width levels (5 chars): DEBUG, INFO, WARNI, ERROR
        -- Normalize truncated levels to full names
        if level == "warni" then
            level = "warning"
        elseif level == "warn" then
            level = "warning"
        end
        record["level"] = level
    else
        -- Default level if not extracted (raw stderr lines)
        record["level"] = "stderr"
    end
    
    -- Ensure message field exists
    if not record["message"] then
        -- If we have a 'log' field (raw log line), use it as message
        if raw_log then
            record["message"] = raw_log
        else
            record["message"] = ""
        end
    end
    
    -- Ensure logger field exists
    if not record["logger"] then
        record["logger"] = "-"
    else
        -- Trim whitespace from logger
        record["logger"] = string.match(record["logger"], "^%s*(.-)%s*$") or record["logger"]
    end
    
    -- Remove raw 'log' field now that we've processed it
    record["log"] = nil
    
    -- Trim whitespace from thread if present
    if record["thread"] then
        record["thread"] = string.match(record["thread"], "^%s*(.-)%s*$") or record["thread"]
    end
    
    -- Extract just the filename from the full path
    -- e.g., /logs/omeroserver/Blitz-0.log.1 -> Blitz-0.log.1
    if record["file"] then
        local filename = string.match(record["file"], "([^/]+)$")
        if filename then
            record["file"] = filename
        end
    end
    
    return 2, timestamp, record
end
