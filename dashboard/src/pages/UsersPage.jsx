import { useEffect, useState } from 'react';
import { usersApi } from '../services/api';

const emptyForm = { name: '', email: '', password: '', role: 'driver' };

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const loadUsers = () => {
    usersApi.list().then((r) => setUsers(r.data)).catch(() => {});
  };

  useEffect(() => { loadUsers(); }, []);

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
        await usersApi.create(form);
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
      <span className={`rounded-full px-3 py-1 text-xs font-medium ${colors[role] || ''}`}>
        {role}
      </span>
    );
  };

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">User Management</h1>
        <button
          onClick={openCreate}
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          + Add User
        </button>
      </div>

      <div className="overflow-hidden rounded-xl border dark:border-gray-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th className="p-4">ID</th>
              <th className="p-4">Name</th>
              <th className="p-4">Email</th>
              <th className="p-4">Role</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-t dark:border-gray-700">
                <td className="p-4">{u.id}</td>
                <td className="p-4 font-medium">{u.name}</td>
                <td className="p-4">{u.email}</td>
                <td className="p-4">{roleBadge(u.role)}</td>
                <td className="p-4 text-right">
                  <button
                    onClick={() => openEdit(u)}
                    className="mr-2 rounded bg-gray-100 px-3 py-1 text-xs font-medium hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDelete(u)}
                    className="rounded bg-red-100 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-200 dark:bg-red-900/30 dark:text-red-300 dark:hover:bg-red-900/50"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <p className="p-8 text-center text-gray-500">No users found</p>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl dark:bg-gray-800">
            <h2 className="mb-4 text-lg font-bold">
              {editingUser ? 'Edit User' : 'Create User'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium">Name</label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="w-full rounded-lg border px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
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
                  className="w-full rounded-lg border px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
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
                  className="w-full rounded-lg border px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                  {...(!editingUser ? { required: true, minLength: 8 } : { minLength: 8 })}
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Role</label>
                <select
                  value={form.role}
                  onChange={(e) => setForm({ ...form, role: e.target.value })}
                  className="w-full rounded-lg border px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
                >
                  <option value="driver">Driver</option>
                  <option value="officer">Traffic Officer</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              {error && <p className="text-sm text-red-600">{error}</p>}
              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="rounded-lg bg-gray-100 px-4 py-2 text-sm hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
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
