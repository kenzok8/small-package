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
+ `fill`: Optional. Available under **local**. Available values ​​refer to **filler**.

#### format

Can be `text` or `yaml` or `mrs`. Rule file format.

#### behavior

Can be `domain` or `ipcidr` or `classical`. Rule file behavior.

#### interval

The update interval for the Rule set, in seconds or /^(\d+)(s|m|h|d)?$/.

#### rawQuery

This parameter is required if the original link contains a url query.\
Encrypt the part `key1=value1&key2=value2` after `?` in the original link with `encodeURIComponent` and use it as the payload of this parameter.

#### filler

Base64edStr format file content.

### Base64edStr

Generation steps:

  1. Base64 encode payload.
  2. Replace all `+` with `-` and all `/` with `_` in base64 string.
  3. Remove all `=` from the EOF the base64 string.

### URIFragment

Ruleset label. Empty strings are not recommended.\
Need encoded by `encodeURIComponent`.
