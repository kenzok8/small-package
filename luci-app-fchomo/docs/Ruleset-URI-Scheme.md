# Import rule-set links format

## Structure

**remote:** `http[s]://[auth@]<host><path>?fmt=<format>&behav=<behavior>[&key=value][#label]`\
**local:**　`file://[host]<path>?fmt=<format>&behav=<behavior>[&fill=<base64edStr>][#label]`\
**inline:** `inline://<Base64edStr>?behav=<behavior>[#label]`

## Components

### Scheme

Can be `http` or `https` or `file` or `inline`.

### Auth

Add it only if required by the target host.

### Host

The format is `hostname[:port]`.\
`hostname` can be **Domain** or **IP Address**.\
`:port` is optional, add it only if required by the target host.

### Path

The shortest format is `/`.

### QueryParameters

+ `fmt`: Required. Available values ​​refer to **format**.
+ `behav`: Required. Available values ​​refer to **behavior**.
+ `sec`: Optional. Available under **remote**. Available values ​​refer to **interval**.
+ `rawq`: Optional. Available under **remote**. Available values ​​refer to **rawQuery**.
+ `hdr`: Optional. Available under **remote**. Available values ​​refer to **header**.
+ `fill`: Optional. Available under **local**. Available values ​​refer to **filler**.
+ `bpath`: Optional. Available when **format** is `mrs`. Available values ​​refer to **bundlePath**.

#### format

Can be `text` or `yaml` or `mrs`. Rule file format.

#### behavior

Can be `domain` or `ipcidr` or `classical`. Rule file behavior.

#### interval

The update interval for the Rule set, in seconds or `/^(\d+)(s|m|h|d)?$/`.

#### rawQuery

This parameter is required if the original link contains a url query.\
Encrypt the part `key1=value1&key2=value2` after `?` in the original link with `encodeURIComponent` and use it as the payload of this parameter.

#### header

JSON format HTTP request headers. Example: `{"User-Agent":["mihomo/1.18.3"]}`.\
Must be encoded as Base64edStr.

#### filler

Base64edStr format file content.

#### bundlePath

The `mrs` file path in `BundleMRS.7z`.\
Need encrypt the original content with `encodeURIComponent`.

### Base64edStr

Encoded steps:

  0. Payload only supports `string` format.
  1. Compress payload using `gzip`. (Optional)
  2. Base64 encode payload/compressed payload.
  3. Replace all `+` with `-` and all `/` with `_` in base64 string.
  4. Remove all `=` from the EOF the base64 string.

### URIFragment

Ruleset label. Empty strings are not recommended.\
Need encoded by `encodeURIComponent`.
