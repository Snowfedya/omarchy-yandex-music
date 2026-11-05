import threading
import unittest
from unittest.mock import MagicMock, patch

import requests
from backend import backend


class RestoreNetworkRetryTests(unittest.TestCase):
    def setUp(self):
        self.player = backend.Player.__new__(backend.Player)
        self.player.lock = threading.Lock()
        self.player.client = None
        self.player.state = {
            "authenticated": False,
            "connecting": False,
            "authPending": False,
            "error": "",
            "loading": False,
            "loadingKind": "",
            "loadingStage": "",
        }

    def test_is_network_error(self):
        self.assertTrue(self.player._is_network_error(requests.exceptions.ConnectionError("Failed to resolve")))
        self.assertTrue(self.player._is_network_error(requests.exceptions.Timeout("Timeout")))
        self.assertTrue(self.player._is_network_error(OSError("[Errno -3] Temporary failure in name resolution")))
        self.assertTrue(self.player._is_network_error(Exception("NameResolutionError in query")))

        # 401 Unauthorized should not be considered a retryable network error
        fake_response = MagicMock(status_code=401)
        http_err = requests.exceptions.HTTPError(response=fake_response)
        self.assertFalse(self.player._is_network_error(http_err))

    @patch("backend.backend.Path.exists", return_value=True)
    @patch("backend.backend.time.sleep", return_value=None)
    def test_restore_retries_on_network_error_and_succeeds(self, mock_sleep, mock_exists):
        calls = 0

        def fake_connect(token):
            nonlocal calls
            calls += 1
            if calls < 3:
                raise requests.exceptions.ConnectionError("Temporary failure in name resolution")
            self.player.state["authenticated"] = True
            self.player.client = MagicMock()

        self.player._load_token = MagicMock(return_value={"access_token": "valid_token", "expires_in": 0})
        self.player._connect = MagicMock(side_effect=fake_connect)
        self.player._restore_queue = MagicMock()

        self.player._restore()

        self.assertEqual(calls, 3)
        self.assertEqual(mock_sleep.call_count, 2)
        self.assertTrue(self.player.state["authenticated"])
        self.assertEqual(self.player.state["error"], "")

    @patch("backend.backend.Path.exists", return_value=True)
    @patch("backend.backend.time.sleep", return_value=None)
    def test_restore_does_not_retry_on_auth_error(self, mock_sleep, mock_exists):
        fake_response = MagicMock(status_code=401)
        auth_error = requests.exceptions.HTTPError("401 Unauthorized", response=fake_response)

        self.player._load_token = MagicMock(return_value={"access_token": "invalid_token", "expires_in": 0})
        self.player._connect = MagicMock(side_effect=auth_error)
        self.player._restore_queue = MagicMock()

        self.player._restore()

        self.assertEqual(mock_sleep.call_count, 0)
        self.assertFalse(self.player.state["authenticated"])
        self.assertIn("401 Unauthorized", self.player.state["error"])

    def test_handle_restore_command(self):
        self.player.restore = MagicMock()
        self.player.status = MagicMock(return_value={"status": "ok"})
        result = self.player.handle({"command": "restore"})
        self.player.restore.assert_called_once()
        self.assertEqual(result, {"status": "ok"})


if __name__ == "__main__":
    unittest.main()
