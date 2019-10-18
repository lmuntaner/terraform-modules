#set ($params = {} )
#foreach ($entry in $context.source)
#if($context.arguments.get($entry.key))
$util.quiet($params.put("${sourcePrefix}$${entry.key}", $entry.value))
#else
$util.quiet($params.put($entry.key, $entry.value))
#end
#end
#foreach ($entry in $context.arguments)
$util.quiet($params.put($entry.key, $entry.value))
#end
{
    "version": "2018-05-29",
    "operation": "Invoke",
    "payload": {
        "headers": $utils.toJson($context.request.headers),
        "user": $utils.toJson($context.identity),
        "params": $utils.toJson($params)
    }
}