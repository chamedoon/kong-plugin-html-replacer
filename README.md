
# Kong Plugin Html Replacer  
A simple plugin to replace text in html responses  
 
## Description  
This plugin replaces text in html responses based on the configuration. It needs the upstream server to set "Content-Type" to "text/html". obviousley other types of responses such as "application/json" or etc would not be modified.

## Installation  
### prequisities
- Kong (obviously)

### Development
If you need the latest version or prefer not to use luarocks repository, follow this steps:
```
$ cd /path-to-your-kong-installation-directory/plugins
$ git clone https://github.com/chamedoon/kong-plugin-html-replacer.git
$ cd kong-plugin-html-replacer
$ luarocks make *.rockspec
```
To make kong aware of this plugin, you'll have to add it's name to the `custom_plugins` property in your configuration file.
```
custom_plugins:
   - html-replacer
```
Restart Kong and have fun.

### luarocks
```
$ luarocks install kong-plugin-html-replacer
```
Don't forget to restart Kong and configure it to use the plugin (see above).

### Configuration
```
$ curl -X POST http://kong:8001/routes/{route_id}/plugins \
    --data "name=html-replacer" \
    --data "config.search=text_to_search"
    --data "config.replace_with=text_to_be_replaced"
```
 | form parameter | default | description |
 |--|--|--|
 | name | -- | The name of this plugin, `html-replacer` |
 |  config.search | ""  | text needs to be replaced in the html response |
 | config.replace_with | ""  | replace text in the html response. **caution: default value is empty string which means searched text would be removed from upstream response** |

## Contribution  
All kind of contributions including bugfixes and improvements are welcomed. PRs need to provide necessary tests and keep test suite in green state ;-)
 
### Run the plugin test suite  
> Running the Kong integration test suite requires both ***Postgres*** and ***Cassandra*** to be installed and configured to be accessible from your Kong instance according to kong/specs/kong_tests.conf in the Kong source tree.
  
If everything is working as it should, you can get started. please make sure you can run the full test suite with your current Kong source.  
  
```  
$ make test-all  
```  

## Useful links
 - [https://docs.konghq.com/1.4.x/plugin-development/](https://docs.konghq.com/1.4.x/plugin-development/)
 - [https://medium.com/@petrousov/developing-kong-plugins-dbec765f5188](https://medium.com/@petrousov/developing-kong-plugins-dbec765f5188)

## Credits
This project exists thanks to [chamedoon](https://chamedoon.com)'s support.

## Author
Ali Ghanavatian

## License
Kong-plugin-html-replaces is [Apache Licensed](https://github.com/chamedoon/kong-plugin-html-replacer/blob/master/LICENSE).
 
