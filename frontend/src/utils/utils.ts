// utils.ts
export const checkIsRegistered = (username: string): boolean => {
    return !!window.localStorage.getItem(username);
};
