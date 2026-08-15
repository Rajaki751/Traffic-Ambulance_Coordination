"""Tests for WebSocket connection manager, channels, and broadcast protocols."""

from unittest.mock import AsyncMock, MagicMock

import pytest

from app.websocket.manager import ChannelType, ConnectionManager


@pytest.mark.asyncio
async def test_connection_manager_connect_and_disconnect():
    mgr = ConnectionManager()
    mock_ws = MagicMock()
    mock_ws.accept = AsyncMock()

    key = await mgr.connect(mock_ws, ChannelType.ADMIN)
    assert key == "admin"
    assert "admin" in mgr._connections
    assert len(mgr._connections["admin"]) == 1

    # Connect driver channel
    mock_driver_ws = MagicMock()
    mock_driver_ws.accept = AsyncMock()
    driver_key = await mgr.connect(mock_driver_ws, ChannelType.DRIVER, identifier="amb-1")
    assert driver_key == "driver:amb-1"
    assert "driver:amb-1" in mgr._connections
    assert len(mgr._connections["driver:amb-1"]) == 1

    # Disconnect admin
    mgr.disconnect(mock_ws, key)
    assert "admin" not in mgr._connections

    # Disconnect driver
    mgr.disconnect(mock_driver_ws, driver_key)
    assert "driver:amb-1" not in mgr._connections


@pytest.mark.asyncio
async def test_broadcast_admin_sends_to_admin_only():
    mgr = ConnectionManager()
    admin_ws = MagicMock()
    admin_ws.accept = AsyncMock()
    admin_ws.send_text = AsyncMock()

    driver_ws = MagicMock()
    driver_ws.accept = AsyncMock()
    driver_ws.send_text = AsyncMock()

    await mgr.connect(admin_ws, ChannelType.ADMIN)
    await mgr.connect(driver_ws, ChannelType.DRIVER, identifier="amb-2")

    await mgr.broadcast_all_admins({"type": "gps_update", "lat": 27.7})

    admin_ws.send_text.assert_called_once()
    driver_ws.send_text.assert_not_called()


@pytest.mark.asyncio
async def test_broadcast_to_officer_sends_to_specific_officer():
    mgr = ConnectionManager()
    off1_ws = MagicMock()
    off1_ws.accept = AsyncMock()
    off1_ws.send_text = AsyncMock()

    off2_ws = MagicMock()
    off2_ws.accept = AsyncMock()
    off2_ws.send_text = AsyncMock()

    await mgr.connect(off1_ws, ChannelType.OFFICER, identifier="101")
    await mgr.connect(off2_ws, ChannelType.OFFICER, identifier="102")

    await mgr.notify_officer(101, {"type": "clearance_request", "junction": "Tripureshwor"})

    off1_ws.send_text.assert_called_once()
    off2_ws.send_text.assert_not_called()


@pytest.mark.asyncio
async def test_broadcast_cleans_up_stale_connections():
    mgr = ConnectionManager()
    dead_ws = MagicMock()
    dead_ws.accept = AsyncMock()
    dead_ws.send_text = AsyncMock(side_effect=RuntimeError("Connection lost"))

    await mgr.connect(dead_ws, ChannelType.ADMIN)
    assert len(mgr._connections["admin"]) == 1

    # Broadcast should catch error and clean up dead websocket
    await mgr.broadcast_all_admins({"type": "heartbeat"})
    assert "admin" not in mgr._connections


@pytest.mark.asyncio
async def test_broadcast_gps_update_reaches_both_admin_and_officers():
    mgr = ConnectionManager()
    admin_ws = MagicMock()
    admin_ws.accept = AsyncMock()
    admin_ws.send_text = AsyncMock()

    off_ws = MagicMock()
    off_ws.accept = AsyncMock()
    off_ws.send_text = AsyncMock()

    driver_ws = MagicMock()
    driver_ws.accept = AsyncMock()
    driver_ws.send_text = AsyncMock()

    await mgr.connect(admin_ws, ChannelType.ADMIN)
    await mgr.connect(off_ws, ChannelType.OFFICER, identifier="99")
    await mgr.connect(driver_ws, ChannelType.DRIVER, identifier="1")

    await mgr.broadcast_gps_update({"type": "live_gps", "ambulance_id": 1, "latitude": 27.7})

    admin_ws.send_text.assert_called_once()
    off_ws.send_text.assert_called_once()
    driver_ws.send_text.assert_not_called()
