import { useCallback, useEffect, useState } from 'react';
import { IconEdit, IconPlus, IconTrash, IconUsers } from '@tabler/icons-react';
import ErrorBanner from '../components/ErrorBanner';
import { usersApi } from '../services/api';

const emptyForm = {
  name: '',
  email: '',
  password: '',
  role: 'driver',
  vehicle_number: '',
  assigned_zone: '',
};

const inputClass =
  'w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-emergency focus:outline-none focus:ring-2 focus:ring-emergency/20 dark:border-gray-600 dark:bg-gray-700 dark:focus:border-emergency-light';

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [error, setError] = useState('');
  const [loadError, setLoadError] = useState('');
  const [loading, setLoading] = useState(false);

  const loadUsers = useCallback(() => {
    setLoadError('');
    usersApi.list()
      .then((r) => setUsers(r.data))
      .catch(() => setLoadError('Failed to load users'));
  }, []);

  useEffect(() => { loadUsers(); }, [loadUsers]);

  const openCreate = () => {
    setEditingUser(null);
    setForm(emptyForm);
    setError('');
    setShowModal(true);
  };

  const openEdit = (u) => {
    setEditingUser(u);
    setForm({ name: u.name, email: u.email, password: '', role: u.role });
    setError('');
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (editingUser) {
        const payload = { name: form.name, email: form.email, role: form.role };
        if (form.password) payload.password = form.password;
        await usersApi.update(editingUser.id, payload);
      } else {
        if (!form.password) {
          setError('Password is required for new users');
          setLoading(false);
          return;
        }
        const payload = {
          name: form.name,
          email: form.email,
          password: form.password,
          role: form.role,
        };
        if (form.role === 'driver') payload.vehicle_number = form.vehicle_number;
        if (form.role === 'officer') payload.assigned_zone = form.assigned_zone;
        await usersApi.create(payload);
      }
      setShowModal(false);
      loadUsers();
    } catch (err) {
      setError(err.response?.data?.detail || 'Operation failed');
    }
    setLoading(false);
  };

  const handleDelete = async (u) => {
    if (!window.confirm(`Delete user "${u.name}" (${u.email})?`)) return;
    try {
      await usersApi.delete(u.id);
      loadUsers();
    } catch (err) {
      alert(err.response?.data?.detail || 'Delete failed');
    }
  };

  const roleBadge = (role) => {
    const colors = {
      admin: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300',
      driver: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
      officer: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
    };
    return (
      <span className={`inline-flex rounded-full px-3 py-1 text-xs font-medium ${colors[role] || ''}`}>
        {role}
      </span>
    );
  };

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">User Management</h1>
        <button
          onClick={openCreate}
          className="flex items-center gap-2 rounded-lg bg-emergency px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emergency-dark"
        >
          <IconPlus className="h-4 w-4" stroke={2} />
          Add User
        </button>
      </div>

      {loadError && <ErrorBanner message={loadError} onRetry={loadUsers} />}

      <div className="overflow-hidden rounded-xl border dark:border-gray-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-100 dark:bg-gray-800">
            <tr className="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400">
              <th className="p-4 font-medium">ID</th>
              <th className="p-4 font-medium">Name</th>
              <th className="p-4 font-medium">Email</th>
              <th className="p-4 font-medium">Role</th>
              <th className="p-4 text-right font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr
                key={u.id}
                className="border-t transition-colors hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800/60"
              >
                <td className="p-4 font-mono text-xs">{u.id}</td>
                <td className="p-4 font-medium">{u.name}</td>
                <td className="p-4 text-gray-600 dark:text-gray-300">{u.email}</td>
                <td className="p-4">{roleBadge(u.role)}</td>
                <td className="p-4 text-right">
                  <button
                    onClick={() => openEdit(u)}
                    title="Edit user"
                    className="mr-2 inline-flex items-center justify-center rounded-lg border p-2 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700 dark:border-gray-600 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-200"
                  >
                    <IconEdit className="h-4 w-4" stroke={1.7} />
                  </button>
                  <button
                    onClick={() => handleDelete(u)}
                    title="Delete user"
                    className="inline-flex items-center justify-center rounded-lg border border-red-200 p-2 text-red-600 transition-colors hover:bg-red-50 dark:border-red-900/50 dark:text-red-400 dark:hover:bg-red-900/30"
                  >
                    <IconTrash className="h-4 w-4" stroke={1.7} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!loadError && users.length === 0 && (
          <div className="p-10 text-center">
            <IconUsers className="mx-auto h-8 w-8 text-gray-300 dark:text-gray-600" stroke={1.5} />
            <p className="mt-3 text-sm text-gray-500">No users found</p>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl border bg-white p-6 shadow-2xl dark:border-gray-700 dark:bg-gray-800">
            <h2 className="mb-4 text-lg font-bold tracking-tight">
              {editingUser ? 'Edit User' : 'Create User'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium">Name</label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className={inputClass}
                  required
                  minLength={2}
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Email</label>
                <input
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  className={inputClass}
                  required
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">
                  Password {editingUser && '(leave blank to keep current)'}
                </label>
                <input
                  type="password"
                  value={form.password}
                  onChange={(e) => setForm({ ...form, password: e.target.value })}
                  className={inputClass}
                  {...(!editingUser ? { required: true, minLength: 8 } : { minLength: 8 })}
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Role</label>
                <select
                  value={form.role}
                  onChange={(e) => setForm({ ...form, role: e.target.value })}
                  className={inputClass}
                >
                  <option value="driver">Driver</option>
                  <option value="officer">Traffic Officer</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              {form.role === 'driver' && (
                <div>
                  <label className="mb-1 block text-sm font-medium">Vehicle Number</label>
                  <input
                    type="text"
                    value={form.vehicle_number}
                    onChange={(e) => setForm({ ...form, vehicle_number: e.target.value })}
                    className={inputClass}
                    required={!editingUser}
                  />
                </div>
              )}
              {form.role === 'officer' && (
                <div>
                  <label className="mb-1 block text-sm font-medium">Assigned Zone</label>
                  <input
                    type="text"
                    value={form.assigned_zone}
                    onChange={(e) => setForm({ ...form, assigned_zone: e.target.value })}
                    className={inputClass}
                    required={!editingUser}
                  />
                </div>
              )}
              {error && (
                <p className="rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-300">
                  {error}
                </p>
              )}
              <div className="flex justify-end gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="rounded-lg border px-4 py-2 text-sm font-medium transition-colors hover:bg-gray-100 dark:border-gray-600 dark:hover:bg-gray-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="rounded-lg bg-emergency px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emergency-dark disabled:opacity-50"
                >
                  {loading ? 'Saving...' : editingUser ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
