module UsersHelper
  # A round profile picture (variant :small or :large, see User), or the first
  # letter of the name in a teal circle when there's no avatar. size is a
  # Tailwind size class pair such as "w-8 h-8".
  def avatar_tag(user, variant: :small, size: "w-8 h-8", **options)
    classes = "#{size} rounded-full flex-none #{options.delete(:class)}"
    if user.avatar.attached? && user.avatar.blob.persisted?
      image_tag avatar_user_path(user, variant, v: user.avatar.blob.id), alt: user.name, class: "#{classes} object-cover", **options
    else
      text = variant == :large ? "text-5xl" : "text-sm"
      tag.span user.name.to_s.first.upcase, aria: { hidden: true },
        class: "#{classes} #{text} inline-flex items-center justify-center bg-teal-700 dark:bg-teal-500 text-white font-medium"
    end
  end
end
