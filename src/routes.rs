// web server imports
use rocket::serde::{json::Json, Deserialize};

pub fn help_txt() -> String {
    "
YAWSIR (Yet Another Web Server In Rust)

USAGE:
    [GET]  /
        This help message

    [POST] /
    [POST DATA] {\"name\": \"My beautiful name\"}
        Sending a POST to `/` with a well formatted JSON data
        with the key \"name\" and your name as the value,
        will instantly brighten your day!

AUTHOR:
    Emanuele \"Lele\" Calo'

LICENSE:
    MIT - 2024
"
    .to_string()
}

#[get("/")]
pub fn index() -> String {
    help_txt()
}

// define JSON data
#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct HelloData<'r> {
    pub name: &'r str,
}

// POST / with HelloData
#[post("/", data = "<hello_data>")]
pub fn hello(hello_data: Json<HelloData<'_>>) -> String {
    let message = std::env::var("MESSAGE").unwrap_or(String::from("Hello"));
    format!("{message}, {}!", hello_data.name)
}

// GET /ping
#[get("/ping")]
pub fn ping() -> String {
    "PONG!".to_string()
}
