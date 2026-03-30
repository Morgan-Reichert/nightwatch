import { useTheme } from "next-themes";
import { Toaster as Sonner, toast } from "sonner";

type ToasterProps = React.ComponentProps<typeof Sonner>;

const Toaster = ({ ...props }: ToasterProps) => {
  const { theme = "system" } = useTheme();

  return (
    <Sonner
      position="top-center"
      theme={theme as ToasterProps["theme"]}
      className="toaster group"
      toastOptions={{
        duration: 4000,
        classNames: {
          toast:
            "rounded-2xl border border-white/30 bg-white/15 backdrop-blur-xl text-black shadow-[0_20px_40px_rgba(0,0,0,0.2)] px-4 py-3",
          title: "font-semibold text-sm",
          description: "text-sm text-slate-700",
          actionButton:
            "inline-flex h-8 items-center justify-center rounded-lg bg-primary/80 px-3 text-xs font-semibold text-white hover:bg-primary",
          cancelButton:
            "inline-flex h-8 items-center justify-center rounded-lg bg-muted/70 px-3 text-xs font-semibold text-muted-foreground hover:bg-muted",
        },
      }}
      {...props}
    />
  );
};

export { Toaster, toast };
