import json
import logging

from firebase_admin import auth, db, initialize_app
from firebase_functions import https_fn

initialize_app(
    options={
        "databaseURL": "https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app"
    }
)


def _json_response(payload: dict, status: int) -> https_fn.Response:
    return https_fn.Response(
        json.dumps(payload),
        status=status,
        headers={"Content-Type": "application/json"},
    )


@https_fn.on_request(
    region="asia-southeast1",
    timeout_sec=60,
    cors=True,
)
def deleteCustomer(request: https_fn.Request) -> https_fn.Response:
    if request.method != "POST":
        return _json_response({"error": "Method not allowed."}, 405)

    authorization = request.headers.get("Authorization", "")
    id_token = authorization[7:] if authorization.startswith("Bearer ") else ""
    body = request.get_json(silent=True) or {}
    customer_uid = body.get("uid", "")
    if not isinstance(customer_uid, str):
        customer_uid = ""
    customer_uid = customer_uid.strip()

    if not id_token or not customer_uid or "/" in customer_uid:
        return _json_response(
            {"error": "Admin token and customer UID are required."}, 400
        )

    try:
        requester = auth.verify_id_token(id_token)
    except auth.ExpiredIdTokenError:
        return _json_response({"error": "Admin session expired. Sign in again."}, 401)
    except Exception:
        return _json_response({"error": "Invalid admin session."}, 401)

    requester_uid = requester.get("uid", "")
    requester_profile = db.reference(f"users/{requester_uid}").get() or {}
    if requester_profile.get("role") != "admin":
        return _json_response({"error": "Only admins can delete customers."}, 403)
    if requester_uid == customer_uid:
        return _json_response(
            {"error": "You cannot delete your own admin account here."}, 400
        )

    customer_ref = db.reference(f"users/{customer_uid}")
    customer = customer_ref.get()
    if not isinstance(customer, dict):
        return _json_response({"error": "Customer was not found."}, 404)
    if customer.get("role") != "customer":
        return _json_response(
            {"error": "Only customer accounts can be deleted here."}, 400
        )

    meter_ids = customer.get("meters", {})
    if not isinstance(meter_ids, dict):
        meter_ids = {}

    updates = {f"users/{customer_uid}": None}
    for meter_id in meter_ids:
        owner_id = db.reference(f"meters/{meter_id}/ownerId").get()
        if owner_id == customer_uid:
            updates[f"meters/{meter_id}/ownerId"] = None

    requests = db.reference("meterRequests").get() or {}
    if isinstance(requests, dict):
        for request_id, meter_request in requests.items():
            if (
                isinstance(meter_request, dict)
                and meter_request.get("customerUid") == customer_uid
            ):
                updates[f"meterRequests/{request_id}"] = None

    try:
        auth.delete_user(customer_uid)
    except auth.UserNotFoundError:
        pass
    except Exception:
        logging.exception("Failed to delete customer Auth account")
        return _json_response({"error": "Customer Auth account could not be deleted."}, 500)

    try:
        db.reference("/").update(updates)
    except Exception:
        logging.exception("Failed to clean customer database records")
        return _json_response(
            {"error": "Auth account was deleted, but database cleanup failed."}, 500
        )

    return _json_response(
        {"ok": True, "unassignedMeters": len(meter_ids)},
        200,
    )
