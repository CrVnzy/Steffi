// Shared email-code login for private Steffi & Yannik pages.
// Data access still depends on Supabase RLS; this file only controls the interface.
(() => {
    window.createSteffiPrivateAuth = function ({ onReady, onLogout }) {
        const byId = (id) => document.getElementById(id);
        const loginPanel = byId("loginPanel");
        const signedInPanel = byId("signedInPanel");
        const memberContent = byId("memberContent");
        const noAccess = byId("noAccess");
        const setupNotice = byId("setupNotice");
        const loginMessage = byId("loginMessage");
        let client = null;
        let pendingOtpEmail = "";
        let activeMemberKey = "";
        let updateSequence = 0;

        function setMessage(text, isError) {
            loginMessage.textContent = text || "";
            loginMessage.classList.toggle("error", Boolean(isError));
        }

        const config = window.STEFFI_SUPABASE;
        if (!window.supabase || !window.supabase.createClient || !config || !config.url || !config.publishableKey) {
            setMessage("Der private Bereich ist gerade nicht erreichbar. Bitte lade die Seite später erneut.", true);
            byId("loginButton").disabled = true;
            return null;
        }

        client = window.supabase.createClient(config.url, config.publishableKey);

        async function requestCode(email, button, resend) {
            button.disabled = true;
            setMessage(resend ? "Ein neuer Code wird angefordert …" : "Der Code wird angefordert …", false);
            try {
                const { error } = await client.auth.signInWithOtp({
                    email,
                    options: { shouldCreateUser: true }
                });
                if (error) throw error;
                pendingOtpEmail = email;
                byId("otpEmail").textContent = email;
                byId("loginForm").hidden = true;
                byId("otpForm").hidden = false;
                byId("otpCode").value = "";
                setMessage(resend
                    ? "Ein neuer Anmeldecode ist unterwegs. Prüfe auch deinen Spam-Ordner."
                    : "Der Anmeldecode ist unterwegs. Lass diese Seite geöffnet und prüfe auch deinen Spam-Ordner.", false);
                if (!resend) byId("otpCode").focus();
            } catch {
                setMessage("Der Code konnte nicht gesendet werden. Bitte prüfe die E-Mail-Adresse und versuche es erneut.", true);
            } finally {
                button.disabled = false;
            }
        }

        byId("loginForm").addEventListener("submit", async (event) => {
            event.preventDefault();
            const email = byId("email").value.trim().toLowerCase();
            await requestCode(email, byId("loginButton"), false);
        });

        byId("otpForm").addEventListener("submit", async (event) => {
            event.preventDefault();
            const button = byId("verifyOtpButton");
            button.disabled = true;
            setMessage("Der Code wird geprüft …", false);
            try {
                if (!pendingOtpEmail) throw new Error("Kein Code angefordert");
                const { error } = await client.auth.verifyOtp({
                    email: pendingOtpEmail,
                    token: byId("otpCode").value.trim(),
                    type: "email"
                });
                if (error) throw error;
                pendingOtpEmail = "";
                byId("otpForm").hidden = true;
                setMessage("Der Code wurde bestätigt. Anmeldung läuft …", false);
                await updateView();
            } catch {
                setMessage("Der Code ist ungültig oder abgelaufen. Bitte prüfe ihn oder fordere einen neuen Code an.", true);
                byId("otpCode").select();
            } finally {
                button.disabled = false;
            }
        });

        byId("resendOtpButton").addEventListener("click", async () => {
            if (pendingOtpEmail) await requestCode(pendingOtpEmail, byId("resendOtpButton"), true);
        });

        byId("changeEmailButton").addEventListener("click", () => {
            pendingOtpEmail = "";
            byId("otpForm").hidden = true;
            byId("loginForm").hidden = false;
            byId("otpCode").value = "";
            setMessage("", false);
            byId("email").focus();
        });

        byId("logoutButton").addEventListener("click", async () => {
            byId("logoutButton").disabled = true;
            const { error } = await client.auth.signOut();
            byId("logoutButton").disabled = false;
            if (error) {
                setMessage("Abmelden hat nicht geklappt. Bitte versuche es erneut.", true);
                return;
            }
            await updateView();
        });

        async function updateView() {
            const sequence = ++updateSequence;
            const { data, error } = await client.auth.getSession();
            if (sequence !== updateSequence) return;
            if (error) {
                setMessage("Deine Anmeldung konnte gerade nicht geprüft werden. Bitte lade die Seite neu.", true);
                return;
            }

            const user = data.session && data.session.user;
            loginPanel.hidden = Boolean(user);
            signedInPanel.hidden = !user;
            noAccess.hidden = true;
            setupNotice.hidden = true;
            memberContent.hidden = true;

            if (!user) {
                const wasSignedIn = Boolean(activeMemberKey);
                activeMemberKey = "";
                setMessage("", false);
                if (wasSignedIn && onLogout) onLogout();
                return;
            }

            const email = (user.email || "").trim().toLowerCase();
            byId("userLabel").textContent = "Angemeldet als " + email;

            const { data: member, error: membershipError } = await client
                .from("gallery_members")
                .select("email")
                .eq("email", email)
                .maybeSingle();
            if (sequence !== updateSequence) return;
            if (membershipError) {
                setMessage("Der private Bereich konnte nicht geladen werden. Bitte versuche es später erneut.", true);
                return;
            }
            if (!member) {
                noAccess.hidden = false;
                activeMemberKey = "";
                return;
            }

            const { data: role, error: roleError } = await client
                .from("couple_member_roles")
                .select("person_key")
                .eq("email", email)
                .maybeSingle();
            if (sequence !== updateSequence) return;
            if (roleError || !role) {
                setupNotice.hidden = false;
                activeMemberKey = "";
                return;
            }

            memberContent.hidden = false;
            setMessage("", false);
            const memberKey = user.id + ":" + role.person_key;
            if (memberKey !== activeMemberKey) {
                activeMemberKey = memberKey;
                if (onReady) await onReady(client, user, role.person_key);
            }
        }

        client.auth.onAuthStateChange(() => {
            window.setTimeout(() => updateView(), 0);
        });
        updateView();
        return client;
    };
})();
