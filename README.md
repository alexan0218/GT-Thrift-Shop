# GT Thrift Shop

The idea our team has is making a mobile application for GT Thrift Shop. This idea came from our experience using Facebook GT thrift shop group page. We, as a team, believe that a mobile application, with improvement and newly added features such as meet-up navigation/on-campus meeting reservation system and direct photos uploads, will make it more convenient for GT students to sell/buy used goods. 

## Team Members

### Yang Yang

### Mengyang Shi

### Wenzhong Jin

### Jihai An

### Yichen Li


#REST API Specification
# Version 1

## POST auth/login

Returns whether the user is a new user or not
### Resource URL

`http://ec2-34-196-222-211.compute-1.amazonaws.com/auth/login`

### Resource Information

* Response Format
	* boolean
* Requires Authentication
	* No
* Rate Limited
    * No

### Parameters
| Parameter               | Description |
| :---                    | :---        |
| `gtusername`<br/>*Required* | |

### Example Requests
* `http://ec2-34-196-222-211.compute-1.amazonaws.com/auth/login?gtusername=gburd1`

### Example Response
```
   True
   False
``` 

  

## GET user/image

Returns the url of the image

### Resource URL

`http://ec2-34-196-222-211.compute-1.amazonaws.com/user/image`

### Resource Information

* Response Format
	* JSON
* Requires Authentication
	* No
* Rate Limited
	* No

### Parameters
| Parameter               | Description |
| :---                    | :---        |
| imagedata               |             |

### Example Requests

* 

### Example Response
#### Image/File share use static file server at `http://34.196.222.211:8000/`, try this address to see some demo picture 
```json
{
	"imagename": "111.jpg",	
  "url":"demo/juru.jpg“
}
```
`the previous url links to 'http://34.196.222.211:8000/demo/juru.jpg`

## POST user/info

Update user info

### Resource URL

`http://ec2-34-196-222-211.compute-1.amazonaws.com/user/info`

### Resource Information

* Response Format
	* JSON
* Requires Authentication
	* No
* Rate Limited
	* No

### Parameters
| Parameter               | Description |
| :---                    | :---        |
| nickname                |             |
| email                   |             |
| avatarURL                |             |
| description                |             |

### Example Requests
* `http://ec2-34-196-222-211.compute-1.amazonaws.com/user/info?nickname=xiaofang&email=lalalu@gmail.com&avatarURL=111.jpg&description=suibia`

### Example Response
``` Integer
ない

```
## Error Codes & Responses

### HTTP Status Codes

| Code | Text | Description |
| :--- | :--- | :---        |
| 200  | OK   | Success!    |
| 400  | Bad Request | The request was invalid or cannot be otherwise served. An accompanying error message will explain further. |
| 404  | Not Found | The URI requested is invalid or the resource requested does not exist. |
| 500  | Internal Server Error | Something is broken and it's not your fault. |
| 503  | Service Unavailable | The service is up, but overloaded with requests. Try again later. |

