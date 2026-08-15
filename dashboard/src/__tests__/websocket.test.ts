/* eslint-disable @typescript-eslint/no-this-alias */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { connectAdminWebSocket } from '../services/websocket';

describe('Admin WebSocket Client', () => {
  let originalWebSocket: any;
  let lastMockInstance: any;

  beforeEach(() => {
    originalWebSocket = window.WebSocket;
    lastMockInstance = null;

    class MockWebSocket {
      static OPEN = 1;
      static CONNECTING = 0;
      static CLOSING = 2;
      static CLOSED = 3;

      url: string;
      readyState = 1;
      send = vi.fn();
      close = vi.fn();
      onopen: any = null;
      onmessage: any = null;
      onerror: any = null;
      onclose: any = null;

      constructor(url: string) {
        this.url = url;
        lastMockInstance = this;
      }
    }

    window.WebSocket = MockWebSocket as any;
  });

  afterEach(() => {
    window.WebSocket = originalWebSocket;
  });

  it('connects to correct live endpoint with token and cleans up', () => {
    const onMessage = vi.fn();
    const onStatusChange = vi.fn();

    const cleanup = connectAdminWebSocket('test_jwt_123', onMessage, { onStatusChange });
    expect(lastMockInstance).not.toBeNull();
    expect(lastMockInstance.url).toContain('/ws/live?token=test_jwt_123&channel=admin');

    cleanup();
    expect(lastMockInstance.close).toHaveBeenCalled();
  });

  it('triggers onSessionExpired and closed status on code 4401', () => {
    const onMessage = vi.fn();
    const onStatusChange = vi.fn();
    const onSessionExpired = vi.fn();

    connectAdminWebSocket('expired_jwt', onMessage, { onStatusChange, onSessionExpired });

    // Simulate WS onclose with code 4401
    lastMockInstance.onclose({ code: 4401 });

    expect(onStatusChange).toHaveBeenCalledWith('closed');
    expect(onSessionExpired).toHaveBeenCalledTimes(1);
  });

  it('triggers onSessionExpired and closed status on code 4403', () => {
    const onMessage = vi.fn();
    const onStatusChange = vi.fn();
    const onSessionExpired = vi.fn();

    connectAdminWebSocket('driver_jwt_on_admin', onMessage, { onStatusChange, onSessionExpired });

    // Simulate WS onclose with code 4403
    lastMockInstance.onclose({ code: 4403 });

    expect(onStatusChange).toHaveBeenCalledWith('closed');
    expect(onSessionExpired).toHaveBeenCalledTimes(1);
  });
});
