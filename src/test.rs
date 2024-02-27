#[cfg(test)]
/// GET / simple test
#[test]
fn get_index() {
    use super::rocket_server;
    use rocket::{http::Status, local::blocking::Client};

    let rocket_test = rocket_server();

    let client = Client::tracked(rocket_test).expect("valid rocket test instance");
    let resp = client.get("/").dispatch();
    assert_eq!(resp.status(), Status::Ok);
}
/// GET /not_found
#[test]
fn get_not_found() {
    use super::rocket_server;
    use rocket::{http::Status, local::blocking::Client};

    let rocket_test = rocket_server();

    let client = Client::tracked(rocket_test).expect("valid rocket test instance");
    let resp = client.get("/not_found").dispatch();
    assert_eq!(resp.status(), Status::NotFound);
}
/// GET / - verify the expected body is returned correctly
#[test]
fn get_index_body() {
    use super::rocket_server;
    use super::routes;
    use rocket::local::blocking::Client;

    let rocket_test = rocket_server();

    let client = Client::tracked(rocket_test).expect("valid rocket test instance");
    let resp = client.get("/").dispatch();
    assert_eq!(
        resp.into_string().expect("basic index help text"),
        routes::help_txt()
    );
}

/// POST / - verify that the body is as expected
#[test]
fn post_index() {
    use super::rocket_server;
    use rocket::local::blocking::Client;

    let rocket_test = rocket_server();

    let client = Client::tracked(rocket_test).expect("valid rocket test instance");
    let user_name = "YAWSIR Fantastic Test User";
    let body_data = format!("{{ \"name\":\"{}\"}}", user_name);
    let resp = client.post("/").body(body_data).dispatch();
    assert_eq!(
        resp.into_string().expect("basic index help text"),
        format!("Hello, {}!", user_name)
    );
}
/// POST / - test invalid well-formed JSON
#[test]
fn post_index_invalid() {
    use super::rocket_server;
    use rocket::{http::Status, local::blocking::Client};

    let rocket_test = rocket_server();

    let client = Client::tracked(rocket_test).expect("valid rocket test instance");
    let body_data = format!("{{ \"not_valid_data\": \"foobar\"}}");
    let resp = client.post("/").body(body_data).dispatch();
    assert_eq!(resp.status(), Status::UnprocessableEntity);
}
/// POST / - test broken JSON
#[test]
fn post_index_broken() {
    use super::rocket_server;
    use rocket::{http::Status, local::blocking::Client};

    let rocket_test = rocket_server();

    let client = Client::tracked(rocket_test).expect("valid rocket test instance");
    let body_data = format!("{{ \"not_valid_data\": \"foo\": \"bar\": \"foo\": \"bar\"}}");
    let resp = client.post("/").body(body_data).dispatch();
    assert_eq!(resp.status(), Status::BadRequest);
}
